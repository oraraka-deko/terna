import { WorkerEntrypoint } from "cloudflare:workers";
import { verifyTelegramInitData } from "./crypto";
import { UserVaultDO } from "./user_vault";
import { TerritoryRoomDO } from "./territory_do";
import { ChatRoomDO } from "./chat_do";
import { executeChatTransfer } from "./transfer_service";
import { PaymentService } from "./payment_service";
import { InventoryService } from "./inventory_service";
import { ChatService } from "./chat_service";
import { createEdgePfReceipt } from "./provably_fair";

export { UserVaultDO, TerritoryRoomDO, ChatRoomDO };

export interface Env {
  USER_VAULT: DurableObjectNamespace<UserVaultDO>;
  TERRITORY_ROOM: DurableObjectNamespace<TerritoryRoomDO>;
  CHAT_ROOM: DurableObjectNamespace<ChatRoomDO>;
  GLOBAL_DB: D1Database;
  AUDIT_QUEUE: Queue;
  TELEGRAM_BOT_TOKEN?: string;
  TONCENTER_API_KEY?: string;
  TONCENTER_NETWORK?: string;
  TONCENTER_BASE_URL?: string;
  TON_TREASURY_ADDRESS?: string;
  DEFAULT_TON_TREASURY_ADDRESS?: string;
  ENVIRONMENT: string;
}

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, HEAD",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Telegram-Init-Data, X-User-Id, X-Username",
  "Access-Control-Max-Age": "86400",
};

function jsonResponse(data: any, init?: ResponseInit): Response {
  const headers = new Headers(init?.headers);
  for (const [k, v] of Object.entries(corsHeaders)) {
    headers.set(k, v);
  }
  headers.set("Content-Type", "application/json");
  return new Response(JSON.stringify(data), {
    ...init,
    headers,
  });
}

/**
 * Direct RPC interface for terna-frontend via Service Binding (0ms edge latency)
 */
export class TernaGatewayEntrypoint extends WorkerEntrypoint<Env> {
  async getUserState(userId: string) {
    const vault = this.env.USER_VAULT.get(this.env.USER_VAULT.idFromName(userId));
    return vault.getState();
  }

  async executeTransfer(params: any) {
    return executeChatTransfer(params, this.env);
  }

  async getChatMessages(query: any) {
    return ChatService.getMessages(query, this.env);
  }

  async sendChatMessage(msg: any) {
    return ChatService.sendMessage(msg, this.env);
  }

  async playPlinko(userId: string, params: any) {
    const vault = this.env.USER_VAULT.get(this.env.USER_VAULT.idFromName(userId));
    return vault.playPlinko(params);
  }

  async playUpgrade(userId: string, params: any) {
    const vault = this.env.USER_VAULT.get(this.env.USER_VAULT.idFromName(userId));
    return vault.playUpgrade(params);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // 0. Public Health Check & Info
      if (url.pathname === "/" || url.pathname === "/health") {
        return jsonResponse({
          status: "healthy",
          service: "terna-gateway",
          version: "2.0.0",
          environment: env.ENVIRONMENT || "production",
          timestamp: Date.now(),
        });
      }

      // Public Gift Shop Catalog via D1 Read Replica
      if (url.pathname === "/api/v1/shop/catalog" && request.method === "GET") {
        if (!env.GLOBAL_DB) return jsonResponse({ items: [] });
        const { results } = await env.GLOBAL_DB.prepare("SELECT * FROM shop_gifts LIMIT 100").all();
        return jsonResponse({ items: results ?? [] });
      }

      // 1. Authenticate Telegram User at the Edge
      const initData = request.headers.get("X-Telegram-Init-Data") || url.searchParams.get("initData") || "";
      const headerUserId = request.headers.get("X-User-Id") || url.searchParams.get("userId");
      let user = {
        id: headerUserId || "demo_user_1",
        username: request.headers.get("X-Username") || "@terna_player",
        photoUrl: "",
      };

      if (env.TELEGRAM_BOT_TOKEN && env.ENVIRONMENT === "production") {
        if (!initData) {
          return jsonResponse({ error: "Unauthorized: Missing Telegram initData" }, { status: 401 });
        }
        user = await verifyTelegramInitData(initData, env.TELEGRAM_BOT_TOKEN);
      } else if (initData && env.TELEGRAM_BOT_TOKEN) {
        user = await verifyTelegramInitData(initData, env.TELEGRAM_BOT_TOKEN);
      }

      // 2. WebSockets Handlers
      if (url.pathname === "/ws/territory") {
        const roomId = env.TERRITORY_ROOM.idFromName("standard-pool");
        const roomStub = env.TERRITORY_ROOM.get(roomId);

        const headers = new Headers(request.headers);
        headers.set("X-User-Id", user.id);
        headers.set("X-Username", user.username);
        headers.set("X-Avatar", user.photoUrl);

        return roomStub.fetch(new Request(request.url, { headers, method: request.method }));
      }

      if (url.pathname === "/ws/chat") {
        const chatRoom = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
        const headers = new Headers(request.headers);
        headers.set("X-User-Id", user.id);
        headers.set("X-Username", user.username);
        return chatRoom.fetch(new Request(request.url, { headers, method: request.method }));
      }

      // 3. User Vault DO Stub
      const vaultId = env.USER_VAULT.idFromName(user.id);
      const vault = env.USER_VAULT.get(vaultId);

      // ----------------------------------------------------
      // 4. USER STATE & INVENTORY
      // ----------------------------------------------------
      if (url.pathname === "/api/v1/user/state" && request.method === "GET") {
        const state = await vault.getState();
        return jsonResponse(state);
      }

      if (url.pathname === "/api/v1/inventory" && request.method === "GET") {
        const inv = await InventoryService.getUserInventory(user.id, env);
        return jsonResponse(inv);
      }

      if (url.pathname === "/api/v1/inventory/buy" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await InventoryService.buyShopGift({ userId: user.id, giftId: body.giftId, currency: body.currency }, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/inventory/sell" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await InventoryService.sellUserGift({ userId: user.id, giftInstanceId: body.giftInstanceId, currency: body.currency }, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/inventory/grant" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await InventoryService.grantGift(body, env);
        return jsonResponse(res);
      }

      // ----------------------------------------------------
      // 5. WALLET & PAYMENTS (TON & TELEGRAM STARS)
      // ----------------------------------------------------
      if (url.pathname === "/api/v1/wallet/config" && request.method === "GET") {
        const config = await PaymentService.getWalletConfig(env);
        return jsonResponse(config);
      }

      if (url.pathname === "/api/v1/wallet/deposit-request" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.createTonDepositRequest({ userId: user.id, amountTon: Number(body.amountTon || 1.0) }, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/verify-ton-deposit" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.verifyTonDeposit(
          {
            userId: user.id,
            depositId: body.depositId,
            boc: body.boc,
            userWalletAddress: body.userWalletAddress,
            amountTon: Number(body.amountTon || 0),
          },
          env
        );
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/stars-invoice" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.createStarsInvoice({ userId: user.id, starsAmount: Number(body.starsAmount) }, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/stars-invoice-status" && request.method === "GET") {
        const invoiceId = url.searchParams.get("invoiceId") || "";
        const res = await PaymentService.getStarsInvoiceStatus(invoiceId, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/stars-paid" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.confirmStarsPayment(
          { userId: user.id, starsAmount: Number(body.starsAmount), invoiceId: body.invoiceId },
          env
        );
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/withdraw-ton" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.requestWithdrawal(
          { userId: user.id, currency: "ton", amount: Number(body.amountTon), destination: body.destinationAddress },
          env
        );
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/wallet/request-stars-withdrawal" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await PaymentService.requestWithdrawal(
          { userId: user.id, currency: "stars", amount: Number(body.amountStars), destination: body.destinationTelegramId || user.id },
          env
        );
        return jsonResponse(res);
      }

      // ----------------------------------------------------
      // 6. SENDING GIFTS TO OTHER USERS & P2P TRANSFERS
      // ----------------------------------------------------
      if (url.pathname === "/api/v1/chat/transfer" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await executeChatTransfer(
          {
            senderId: user.id,
            senderName: user.username,
            senderAvatar: user.photoUrl,
            recipientId: body.recipientId,
            recipientName: body.recipientName,
            type: body.type,
            amount: body.amount,
            giftInstanceId: body.giftInstanceId,
          },
          env
        );
        return jsonResponse(res, { status: res.success ? 200 : 400 });
      }

      // ----------------------------------------------------
      // 7. CHAT MESSAGING, GROUPS & FRIENDSHIPS
      // ----------------------------------------------------
      if (url.pathname === "/api/v1/chat/messages" && request.method === "GET") {
        const scope = url.searchParams.get("scope") || "GLOBAL";
        const channelId = url.searchParams.get("channelId") || "global";
        const recipientId = url.searchParams.get("recipientId") || undefined;
        const limit = Number(url.searchParams.get("limit") || 50);

        const messages = await ChatService.getMessages(
          { scope, channelId, senderId: user.id, recipientId, limit },
          env
        );
        return jsonResponse({ messages });
      }

      if (url.pathname === "/api/v1/chat/message" && request.method === "POST") {
        const body = (await request.json()) as any;
        const sent = await ChatService.sendMessage(
          {
            ...body,
            senderId: user.id,
            senderName: user.username,
            senderAvatar: user.photoUrl,
          },
          env
        );
        return jsonResponse({ success: true, message: sent });
      }

      if (url.pathname === "/api/v1/chat/reaction" && request.method === "POST") {
        const { messageId, emoji } = (await request.json()) as any;
        const chatRoom = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
        await chatRoom.toggleReaction(messageId, emoji, user.id);
        return jsonResponse({ success: true });
      }

      if (url.pathname === "/api/v1/chat/seen" && request.method === "POST") {
        const { messageIds } = (await request.json()) as any;
        const chatRoom = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
        await chatRoom.markSeen(messageIds, user.id);
        return jsonResponse({ success: true });
      }

      if (url.pathname === "/api/v1/chat/groups" && request.method === "GET") {
        const groups = await ChatService.getGroups(user.id, env);
        return jsonResponse({ groups });
      }

      if (url.pathname === "/api/v1/chat/groups/create" && request.method === "POST") {
        const body = (await request.json()) as any;
        const created = await ChatService.createGroup({ ...body, creatorId: user.id }, env);
        return jsonResponse({ success: true, group: created });
      }

      if (url.pathname === "/api/v1/chat/groups/join" && request.method === "POST") {
        const { groupId } = (await request.json()) as any;
        const res = await ChatService.joinGroup(groupId, user.id, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/chat/groups/leave" && request.method === "POST") {
        const { groupId } = (await request.json()) as any;
        const res = await ChatService.leaveGroup(groupId, user.id, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/chat/friends" && request.method === "GET") {
        const friends = await ChatService.getFriends(user.id, env);
        return jsonResponse({ friends });
      }

      if (url.pathname === "/api/v1/chat/friends/request" && request.method === "POST") {
        const { friendId } = (await request.json()) as any;
        const res = await ChatService.sendFriendRequest(user.id, friendId, env);
        return jsonResponse(res);
      }

      if (url.pathname === "/api/v1/chat/friends/respond" && request.method === "POST") {
        const { friendId, status } = (await request.json()) as any;
        const res = await ChatService.respondFriendRequest(user.id, friendId, status, env);
        return jsonResponse(res);
      }

      if (url.pathname.startsWith("/api/v1/chat/bio/") && request.method === "GET") {
        const targetUserId = url.pathname.replace("/api/v1/chat/bio/", "");
        const bio = await ChatService.getUserBio(targetUserId, env);
        return jsonResponse({ bio });
      }

      if (url.pathname === "/api/v1/chat/bio" && request.method === "POST") {
        const body = (await request.json()) as any;
        const res = await ChatService.updateUserBio({ ...body, userId: user.id }, env);
        return jsonResponse(res);
      }

      // ----------------------------------------------------
      // 8. PROVABLY FAIR GAMES (TOWER, PLINKO, UPGRADE, HIGHER/LOWER, MINES, ROULETTE)
      // ----------------------------------------------------
      if (url.pathname === "/api/v1/play/upgrade" && request.method === "POST") {
        const body = (await request.json()) as any;
        const result = await vault.playUpgrade(body);
        return jsonResponse(result);
      }

      if (url.pathname === "/api/v1/play/plinko" && request.method === "POST") {
        const body = (await request.json()) as any;
        const result = await vault.playPlinko(body);
        return jsonResponse(result);
      }

      if (url.pathname === "/api/v1/tower/start" && request.method === "POST") {
        const body = (await request.json()) as any;
        return jsonResponse(await vault.startTower(body));
      }

      if (url.pathname === "/api/v1/tower/pick" && request.method === "POST") {
        const { colIndex } = (await request.json()) as { colIndex: number };
        return jsonResponse(await vault.pickTowerTile(colIndex));
      }

      if (url.pathname === "/api/v1/tower/cashout" && request.method === "POST") {
        return jsonResponse(await vault.cashOutTower(false));
      }

      if (url.pathname === "/api/v1/higher-lower/start" && request.method === "POST") {
        const body = (await request.json()) as any;
        return jsonResponse(await vault.startHigherLower(body));
      }

      if (url.pathname === "/api/v1/higher-lower/guess" && request.method === "POST") {
        const { call } = (await request.json()) as { call: "higher" | "lower" | "skip" };
        return jsonResponse(await vault.guessHigherLower(call));
      }

      if (url.pathname === "/api/v1/higher-lower/cashout" && request.method === "POST") {
        return jsonResponse(await vault.cashOutHigherLower());
      }

      if (url.pathname === "/api/v1/mines/start" && request.method === "POST") {
        const body = (await request.json()) as any;
        return jsonResponse(await vault.startMines(body));
      }

      if (url.pathname === "/api/v1/mines/reveal" && request.method === "POST") {
        const { tileIndex } = (await request.json()) as { tileIndex: number };
        return jsonResponse(await vault.revealMineTile(tileIndex));
      }

      if (url.pathname === "/api/v1/mines/cashout" && request.method === "POST") {
        return jsonResponse(await vault.cashOutMines(false));
      }

      if (url.pathname === "/api/v1/roulette/spin" && request.method === "POST") {
        const body = (await request.json()) as any;
        return jsonResponse(await vault.playRoulette(body));
      }

      if (url.pathname.startsWith("/api/v1/games/proof/")) {
        const roundId = url.pathname.replace("/api/v1/games/proof/", "");
        if (env.GLOBAL_DB) {
          const round = await env.GLOBAL_DB.prepare("SELECT * FROM game_rounds WHERE id = ?").bind(roundId).first<any>();
          if (round) {
            const receipt = createEdgePfReceipt({
              game: round.game_id,
              roundId: round.id,
              serverSeed: round.server_seed || "",
              serverSeedHash: round.server_seed_hash || "",
              clientSeed: round.client_seed || "",
              nonce: round.nonce || 0,
              outcomes: JSON.parse(round.game_details || "[]"),
              status: round.status,
              payout: round.payout_amount,
            });
            return jsonResponse(receipt);
          }
        }
        return jsonResponse({ error: "Round proof not found" }, { status: 404 });
      }

      return jsonResponse({ error: "Route not found" }, { status: 404 });
    } catch (err: any) {
      return jsonResponse({ error: err.message || "Internal Edge Error" }, { status: 400 });
    }
  },

  // Background Queue Consumer: Batches game audit logs into D1 without slowing down gameplay
  async queue(batch: MessageBatch<any>, env: Env): Promise<void> {
    const stmt = env.GLOBAL_DB.prepare(
      `INSERT INTO game_audit_logs (id, user_id, game_type, currency, bet_amount, payout_amount, server_seed, client_seed, nonce, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    );
    const batchStmts = batch.messages.map((m) => {
      const d = m.body;
      return stmt.bind(d.id, d.userId, d.gameType, d.currency, d.bet, d.payout, d.serverSeed, d.clientSeed, d.nonce, Date.now());
    });
    if (batchStmts.length > 0) {
      await env.GLOBAL_DB.batch(batchStmts);
    }
  },
};
