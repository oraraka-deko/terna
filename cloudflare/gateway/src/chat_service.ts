import { Env } from "./index";
import { ChatMessagePayload } from "./chat_do";

export class ChatService {
  /**
   * 1. GET CHAT MESSAGES
   */
  static async getMessages(
    query: {
      scope?: string;
      channelId?: string;
      senderId?: string;
      recipientId?: string;
      limit?: number;
    },
    env: Env
  ): Promise<ChatMessagePayload[]> {
    const limit = Math.min(100, query.limit || 50);
    const scope = (query.scope || "GLOBAL").toUpperCase();
    const channelId = query.channelId || "global";

    // If global scope, get from ChatRoomDO fast memory cache
    if (scope === "GLOBAL" && channelId === "global") {
      const room = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
      return room.getRecentMessages("global", limit);
    }

    if (!env.GLOBAL_DB) return [];

    let stmt: any;
    if (scope === "DIRECT" && query.senderId && query.recipientId) {
      stmt = env.GLOBAL_DB.prepare(
        `SELECT * FROM app_chat_messages 
         WHERE scope = 'DIRECT' AND ((sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?))
         ORDER BY created_at DESC LIMIT ?`
      ).bind(query.senderId, query.recipientId, query.recipientId, query.senderId, limit);
    } else {
      stmt = env.GLOBAL_DB.prepare(
        `SELECT * FROM app_chat_messages 
         WHERE channel_id = ? 
         ORDER BY created_at DESC LIMIT ?`
      ).bind(channelId, limit);
    }

    const { results } = await stmt.all();
    const rows = (results || []) as any[];

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

  /**
   * 2. SEND CHAT MESSAGE
   */
  static async sendMessage(msg: Partial<ChatMessagePayload>, env: Env): Promise<ChatMessagePayload> {
    const payload: ChatMessagePayload = {
      id: msg.id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      scope: msg.scope || "GLOBAL",
      channelId: msg.channelId || "global",
      senderId: msg.senderId || "unknown",
      senderName: msg.senderName || "Player",
      senderAvatar: msg.senderAvatar,
      badge: msg.badge,
      recipientId: msg.recipientId,
      recipientName: msg.recipientName,
      text: String(msg.text || "").trim(),
      replyToId: msg.replyToId,
      replyPreview: msg.replyPreview,
      reactions: {},
      seenBy: [msg.senderId || "unknown"],
      transfer: msg.transfer,
      createdAt: Date.now(),
    };

    const room = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
    await room.broadcastMessage(payload);

    return payload;
  }

  /**
   * 3. CHAT GROUPS
   */
  static async getGroups(userId: string, env: Env) {
    if (!env.GLOBAL_DB) return [];
    const { results } = await env.GLOBAL_DB.prepare("SELECT * FROM chat_groups ORDER BY created_at ASC").all();
    const groups = (results || []) as any[];
    return groups
      .map((g) => ({
        id: g.id,
        name: g.name,
        description: g.description,
        icon: g.icon,
        creatorId: g.creator_id,
        isPrivate: g.is_private === 1,
        members: JSON.parse(g.members || "[]"),
        mutedBy: JSON.parse(g.muted_by || "[]"),
        createdAt: g.created_at,
      }))
      .filter((g) => !g.isPrivate || g.creatorId === userId || g.members.includes(userId));
  }

  static async createGroup(
    params: { name: string; description?: string; icon?: string; creatorId: string; isPrivate?: boolean },
    env: Env
  ) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const id = `grp_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const now = Date.now();
    const members = JSON.stringify([params.creatorId]);

    await env.GLOBAL_DB.prepare(
      `INSERT INTO chat_groups (id, name, description, icon, creator_id, is_private, members, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        id,
        params.name,
        params.description || "",
        params.icon || "💬",
        params.creatorId,
        params.isPrivate ? 1 : 0,
        members,
        now,
        now
      )
      .run();

    return { id, name: params.name, creatorId: params.creatorId, members: [params.creatorId] };
  }

  static async joinGroup(groupId: string, userId: string, env: Env) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const group = await env.GLOBAL_DB.prepare("SELECT * FROM chat_groups WHERE id = ?").bind(groupId).first<any>();
    if (!group) throw new Error("Group not found");

    const members: string[] = JSON.parse(group.members || "[]");
    if (!members.includes(userId)) {
      members.push(userId);
      await env.GLOBAL_DB.prepare("UPDATE chat_groups SET members = ?, updated_at = ? WHERE id = ?")
        .bind(JSON.stringify(members), Date.now(), groupId)
        .run();
    }
    return { success: true, members };
  }

  static async leaveGroup(groupId: string, userId: string, env: Env) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const group = await env.GLOBAL_DB.prepare("SELECT * FROM chat_groups WHERE id = ?").bind(groupId).first<any>();
    if (!group) throw new Error("Group not found");

    let members: string[] = JSON.parse(group.members || "[]");
    members = members.filter((m) => m !== userId);
    await env.GLOBAL_DB.prepare("UPDATE chat_groups SET members = ?, updated_at = ? WHERE id = ?")
      .bind(JSON.stringify(members), Date.now(), groupId)
      .run();

    return { success: true, members };
  }

  /**
   * 4. FRIENDSHIPS
   */
  static async getFriends(userId: string, env: Env) {
    if (!env.GLOBAL_DB) return [];
    const { results } = await env.GLOBAL_DB.prepare(
      `SELECT f.*, u.username, u.first_name, u.avatar 
       FROM user_friendships f
       LEFT JOIN app_users u ON u.id = f.friend_id
       WHERE f.user_id = ?`
    )
      .bind(userId)
      .all();
    return results || [];
  }

  static async sendFriendRequest(userId: string, friendId: string, env: Env) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const now = Date.now();
    await env.GLOBAL_DB.prepare(
      `INSERT OR REPLACE INTO user_friendships (user_id, friend_id, status, created_at, updated_at)
       VALUES (?, ?, 'PENDING', ?, ?)`
    )
      .bind(userId, friendId, now, now)
      .run();

    return { success: true };
  }

  static async respondFriendRequest(userId: string, friendId: string, status: "ACCEPTED" | "BLOCKED", env: Env) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const now = Date.now();
    await env.GLOBAL_DB.prepare(
      `UPDATE user_friendships SET status = ?, updated_at = ? 
       WHERE user_id = ? AND friend_id = ?`
    )
      .bind(status, now, friendId, userId)
      .run();

    if (status === "ACCEPTED") {
      await env.GLOBAL_DB.prepare(
        `INSERT OR REPLACE INTO user_friendships (user_id, friend_id, status, created_at, updated_at)
         VALUES (?, ?, 'ACCEPTED', ?, ?)`
      )
        .bind(userId, friendId, now, now)
        .run();
    }

    return { success: true, status };
  }

  /**
   * 5. BIO & USER PROFILE
   */
  static async getUserBio(userId: string, env: Env) {
    if (!env.GLOBAL_DB) return null;
    return env.GLOBAL_DB.prepare("SELECT id, username, first_name, avatar, custom_name, custom_avatar, bio FROM app_users WHERE id = ?")
      .bind(userId)
      .first<any>();
  }

  static async updateUserBio(
    params: { userId: string; bio?: string; customName?: string; customAvatar?: string },
    env: Env
  ) {
    if (!env.GLOBAL_DB) throw new Error("Database offline");
    const now = Date.now();
    await env.GLOBAL_DB.prepare(
      `INSERT INTO app_users (id, bio, custom_name, custom_avatar, last_seen_at, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         bio = COALESCE(?, bio),
         custom_name = COALESCE(?, custom_name),
         custom_avatar = COALESCE(?, custom_avatar),
         updated_at = ?`
    )
      .bind(
        params.userId,
        params.bio || null,
        params.customName || null,
        params.customAvatar || null,
        now,
        now,
        now,
        params.bio || null,
        params.customName || null,
        params.customAvatar || null,
        now
      )
      .run();

    return { success: true };
  }
}

