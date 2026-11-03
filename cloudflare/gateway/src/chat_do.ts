import { DurableObject } from "cloudflare:workers";

export interface ChatMessagePayload {
  id: string;
  scope: "GLOBAL" | "DIRECT" | "GROUP";
  channelId: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  badge?: string;
  recipientId?: string;
  recipientName?: string;
  text: string;
  replyToId?: string;
  replyPreview?: any;
  reactions?: Record<string, string[]>;
  seenBy?: string[];
  transfer?: any;
  createdAt: number;
}

interface ChatSocketAttachment {
  userId: string;
  username: string;
}

export class ChatRoomDO extends DurableObject {
  sql: SqlStorage;
  env: any;

  constructor(ctx: DurableObjectState, env: any) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.env = env;

    // Embedded 0ms SQLite for caching recent messages
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS recent_messages (
        id TEXT PRIMARY KEY,
        scope TEXT NOT NULL,
        channel_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_avatar TEXT,
        badge TEXT,
        recipient_id TEXT,
        recipient_name TEXT,
        text TEXT NOT NULL,
        reply_to_id TEXT,
        reply_preview TEXT,
        reactions TEXT NOT NULL DEFAULT '{}',
        seen_by TEXT NOT NULL DEFAULT '[]',
        transfer TEXT,
        created_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_recent_channel ON recent_messages(channel_id, created_at DESC);
    `);
  }

  // 1. WebSocket Upgrade and Connection Management with Hibernation Support
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      const userId = request.headers.get("X-User-Id") || url.searchParams.get("userId") || "guest";
      const username = request.headers.get("X-Username") || url.searchParams.get("username") || "Player";

      this.ctx.acceptWebSocket(server);
      server.serializeAttachment({ userId, username } satisfies ChatSocketAttachment);

      const onlineCount = this.ctx.getWebSockets().length;

      // Send initial welcome & online count
      server.send(
        JSON.stringify({
          type: "CONNECTED",
          userId,
          onlineCount,
        })
      );

      // Broadcast updated online count
      this.broadcast({
        type: "ONLINE_COUNT",
        onlineCount,
      });

      return new Response(null, { status: 101, webSocket: client });
    }

    return new Response("Expected WebSocket", { status: 426 });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    try {
      const data = JSON.parse(typeof message === "string" ? message : new TextDecoder().decode(message));
      const session = ws.deserializeAttachment() as ChatSocketAttachment | null;
      if (!session) return;

      if (data.type === "CHAT_MESSAGE") {
        const msg: ChatMessagePayload = {
          id: data.id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
          scope: data.scope || "GLOBAL",
          channelId: data.channelId || "global",
          senderId: session.userId,
          senderName: session.username,
          senderAvatar: data.avatar || "",
          badge: data.badge,
          recipientId: data.recipientId,
          recipientName: data.recipientName,
          text: String(data.text || "").trim(),
          replyToId: data.replyToId,
          replyPreview: data.replyPreview,
          reactions: {},
          seenBy: [session.userId],
          transfer: data.transfer,
          createdAt: Date.now(),
        };

        if (msg.text || msg.transfer) {
          await this.saveMessage(msg);
          this.broadcast({
            type: "CHAT_MESSAGE",
            message: msg,
            onlineCount: this.ctx.getWebSockets().length,
          });
        }
      } else if (data.type === "REACTION") {
        await this.toggleReaction(data.messageId, data.emoji, session.userId);
      } else if (data.type === "SEEN") {
        await this.markSeen(data.messageIds || [data.messageId], session.userId);
      }
    } catch (e) {
      console.error("[ChatRoomDO] Message handling error:", e);
    }
  }

  async webSocketClose(ws: WebSocket) {
    this.broadcast({
      type: "ONLINE_COUNT",
      onlineCount: this.ctx.getWebSockets().length,
    });
  }

  async webSocketError(ws: WebSocket) {
    // Handled automatically by DO runtime
  }

  // 2. RPC Methods
  async saveMessage(msg: ChatMessagePayload): Promise<void> {
    this.sql.exec(
      `INSERT OR REPLACE INTO recent_messages 
       (id, scope, channel_id, sender_id, sender_name, sender_avatar, badge, recipient_id, recipient_name, text, reply_to_id, reply_preview, reactions, seen_by, transfer, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      msg.id,
      msg.scope,
      msg.channelId,
      msg.senderId,
      msg.senderName,
      msg.senderAvatar || null,
      msg.badge || null,
      msg.recipientId || null,
      msg.recipientName || null,
      msg.text,
      msg.replyToId || null,
      msg.replyPreview ? JSON.stringify(msg.replyPreview) : null,
      JSON.stringify(msg.reactions || {}),
      JSON.stringify(msg.seenBy || []),
      msg.transfer ? JSON.stringify(msg.transfer) : null,
      msg.createdAt
    );

    // Fast indexed prune of messages older than 200 without full table scan
    this.sql.exec(
      `DELETE FROM recent_messages 
       WHERE created_at < (
         SELECT created_at FROM recent_messages 
         WHERE channel_id = ? 
         ORDER BY created_at DESC 
         LIMIT 1 OFFSET 200
       ) AND channel_id = ?`,
      msg.channelId,
      msg.channelId
    );

    // Persist to D1 in background via waitUntil
    if (this.env.GLOBAL_DB) {
      const d1Promise = this.env.GLOBAL_DB.prepare(
        `INSERT OR REPLACE INTO app_chat_messages 
         (id, scope, channel_id, sender_id, sender_name, sender_avatar, badge, recipient_id, recipient_name, text, reply_to_id, reply_preview, reactions, seen_by, transfer, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(
          msg.id,
          msg.scope,
          msg.channelId,
          msg.senderId,
          msg.senderName,
          msg.senderAvatar || null,
          msg.badge || null,
          msg.recipientId || null,
          msg.recipientName || null,
          msg.text,
          msg.replyToId || null,
          msg.replyPreview ? JSON.stringify(msg.replyPreview) : null,
          JSON.stringify(msg.reactions || {}),
          JSON.stringify(msg.seenBy || []),
          msg.transfer ? JSON.stringify(msg.transfer) : null,
          msg.createdAt
        )
        .run()
        .catch((err: any) => console.error("[ChatRoomDO] D1 persist error:", err));

      this.ctx.waitUntil(d1Promise);
    }
  }

  async broadcastMessage(msg: ChatMessagePayload): Promise<void> {
    await this.saveMessage(msg);
    this.broadcast({
      type: "CHAT_MESSAGE",
      message: msg,
      onlineCount: this.ctx.getWebSockets().length,
    });
  }

  async getRecentMessages(channelId = "global", limit = 50): Promise<ChatMessagePayload[]> {
    const rows = this.sql
      .exec<any>(
        "SELECT * FROM recent_messages WHERE channel_id = ? ORDER BY created_at DESC LIMIT ?",
        channelId,
        limit
      )
      .toArray();

    return rows.reverse().map((r) => ({
      id: r.id,
      scope: r.scope,
      channelId: r.channel_id,
      senderId: r.sender_id,
      senderName: r.sender_name,
      senderAvatar: r.sender_avatar,
      badge: r.badge,
      recipientId: r.recipient_id,
      recipientName: r.recipient_name,
      text: r.text,
      replyToId: r.reply_to_id,
      replyPreview: r.reply_preview ? JSON.parse(r.reply_preview) : undefined,
      reactions: r.reactions ? JSON.parse(r.reactions) : {},
      seenBy: r.seen_by ? JSON.parse(r.seen_by) : [],
      transfer: r.transfer ? JSON.parse(r.transfer) : undefined,
      createdAt: r.created_at,
    }));
  }

  async toggleReaction(messageId: string, emoji: string, userId: string) {
    const row = this.sql.exec<{ reactions: string }>("SELECT reactions FROM recent_messages WHERE id = ?", messageId).toArray()[0];
    if (!row) return;

    const reactions: Record<string, string[]> = JSON.parse(row.reactions || "{}");
    if (!reactions[emoji]) reactions[emoji] = [];

    const existingIdx = reactions[emoji].indexOf(userId);
    if (existingIdx >= 0) {
      reactions[emoji].splice(existingIdx, 1);
      if (reactions[emoji].length === 0) delete reactions[emoji];
    } else {
      reactions[emoji].push(userId);
    }

    this.sql.exec("UPDATE recent_messages SET reactions = ? WHERE id = ?", JSON.stringify(reactions), messageId);

    this.broadcast({
      type: "REACTION_UPDATE",
      messageId,
      reactions,
    });
  }

  async markSeen(messageIds: string[], userId: string) {
    for (const id of messageIds) {
      const row = this.sql.exec<{ seen_by: string }>("SELECT seen_by FROM recent_messages WHERE id = ?", id).toArray()[0];
      if (row) {
        const seen: string[] = JSON.parse(row.seen_by || "[]");
        if (!seen.includes(userId)) {
          seen.push(userId);
          this.sql.exec("UPDATE recent_messages SET seen_by = ? WHERE id = ?", JSON.stringify(seen), id);
        }
      }
    }

    this.broadcast({
      type: "SEEN_UPDATE",
      messageIds,
      userId,
    });
  }

  private broadcast(data: any) {
    const payload = JSON.stringify(data);
    for (const ws of this.ctx.getWebSockets()) {
      try {
        ws.send(payload);
      } catch (_) {}
    }
  }
}
