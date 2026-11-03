import { DurableObject } from "cloudflare:workers";
import { computeProvablyFairRoll, generateRandomSeedHex, sha256Hex } from "./crypto";

interface PlayerBetRow {
  player_id: string;
  username: string;
  avatar: string;
  color_hex: string;
  ton_bet: number;
  stars_bet: number;
  weight_ton_equiv: number;
}

const PALETTE = ["#2DD4BF", "#F43F5E", "#A855F7", "#FBBF24", "#38BDF8", "#4ADE80", "#FB923C"];

export class TerritoryRoomDO extends DurableObject {
  sql: SqlStorage;
  env: any;

  constructor(ctx: DurableObjectState, env: any) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.env = env;

    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS round_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        round_id INTEGER NOT NULL,
        status TEXT NOT NULL, -- 'waitingForPlayers' | 'bettingOpen' | 'roundResolving'
        server_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL,
        closes_at_ms INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS active_bets (
        player_id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        ton_bet REAL NOT NULL DEFAULT 0,
        stars_bet INTEGER NOT NULL DEFAULT 0,
        weight_ton_equiv REAL NOT NULL DEFAULT 0
      );
    `);
  }

  private async ensureRoundExists() {
    const rows = this.sql.exec("SELECT round_id FROM round_state WHERE id = 1").toArray();
    if (rows.length === 0) {
      const seed = generateRandomSeedHex(32);
      const hash = await sha256Hex(seed);
      this.sql.exec(
        "INSERT INTO round_state (id, round_id, status, server_seed, server_seed_hash, closes_at_ms) VALUES (1, 1001, 'waitingForPlayers', ?, ?, 0)",
        seed,
        hash
      );
    }
  }

  // Handle incoming WebSocket upgrade requests
  async fetch(request: Request): Promise<Response> {
    await this.ensureRoundExists();
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket", { status: 426 });
    }

    const userId = request.headers.get("X-User-Id")!;
    const username = request.headers.get("X-Username")!;
    const avatar = request.headers.get("X-Avatar") || "";

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    // WebSocket Hibernation API: attaches user metadata to the socket
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ userId, username, avatar });

    // Send immediate snapshot to the newly connected client
    server.send(JSON.stringify(this.getSnapshotPayload()));

    return new Response(null, { status: 101, webSocket: client });
  }

  // Triggered when a player sends a message over WebSocket (e.g. placing a bet)
  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    try {
      const data = JSON.parse(typeof message === "string" ? message : new TextDecoder().decode(message));
      if (data.action === "place_bet") {
        const user = ws.deserializeAttachment() as { userId: string; username: string; avatar: string };
        await this.handlePlaceBet(user, data.currency, Number(data.amount));
      }
    } catch (err: any) {
      ws.send(JSON.stringify({ type: "error", message: err.message }));
    }
  }

  private async handlePlaceBet(
    user: { userId: string; username: string; avatar: string },
    currency: "ton" | "stars",
    amount: number
  ) {
    const state = this.sql
      .exec<{ round_id: number; status: string; closes_at_ms: number }>(
        "SELECT round_id, status, closes_at_ms FROM round_state WHERE id = 1"
      )
      .one();

    if (state.status === "roundResolving") {
      throw new Error("Round is currently resolving");
    }

    // 1. Call player's UserVaultDO via internal RPC to deduct balance atomically
    const vaultId = this.env.USER_VAULT.idFromName(user.userId);
    const vaultStub = this.env.USER_VAULT.get(vaultId);
    await vaultStub.deductPvpBet(currency, amount);

    // 2. Record bet in TerritoryRoomDO's local SQLite
    const weightDelta = currency === "ton" ? amount : amount / 100.0;
    const existingPlayers = this.sql.exec("SELECT COUNT(*) as cnt FROM active_bets").one() as { cnt: number };
    const assignedColor = PALETTE[existingPlayers.cnt % PALETTE.length];

    this.sql.exec(
      `INSERT INTO active_bets (player_id, username, avatar, color_hex, ton_bet, stars_bet, weight_ton_equiv)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(player_id) DO UPDATE SET
         ton_bet = ton_bet + excluded.ton_bet,
         stars_bet = stars_bet + excluded.stars_bet,
         weight_ton_equiv = weight_ton_equiv + excluded.weight_ton_equiv`,
      user.userId,
      user.username,
      user.avatar,
      assignedColor,
      currency === "ton" ? amount : 0,
      currency === "stars" ? Math.round(amount) : 0,
      weightDelta
    );

    // 3. Start 15-second countdown as soon as at least 2 distinct players have bet
    const updatedCount = (this.sql.exec("SELECT COUNT(*) as cnt FROM active_bets").one() as { cnt: number }).cnt;
    if (state.status === "waitingForPlayers" && updatedCount >= 2) {
      const closesAt = Date.now() + 15000;
      this.sql.exec("UPDATE round_state SET status = 'bettingOpen', closes_at_ms = ? WHERE id = 1", closesAt);
      await this.ctx.storage.setAlarm(closesAt);
    }

    // 4. Broadcast updated pot & player territories to all connected clients
    this.broadcast(this.getSnapshotPayload());
  }

  // Hardware-backed timer fires when the 15s betting window ends
  async alarm() {
    const state = this.sql
      .exec<{ round_id: number; status: string; server_seed: string; server_seed_hash: string }>(
        "SELECT * FROM round_state WHERE id = 1"
      )
      .one();

    if (state.status === "bettingOpen") {
      const bets = this.sql
        .exec<PlayerBetRow>("SELECT * FROM active_bets ORDER BY weight_ton_equiv DESC")
        .toArray();

      const totalWeight = bets.reduce((acc, b) => acc + b.weight_ton_equiv, 0);
      const totalTonPot = bets.reduce((acc, b) => acc + b.ton_bet, 0);
      const totalStarsPot = bets.reduce((acc, b) => acc + b.stars_bet, 0);

      // Provably fair weighted winner selection
      const roll = await computeProvablyFairRoll(state.server_seed, `round_${state.round_id}`, state.round_id);
      const winningTicket = (roll.rollPercentile / 100.0) * totalWeight;

      let cumulative = 0;
      let winner = bets[0];
      for (const b of bets) {
        cumulative += b.weight_ton_equiv;
        if (winningTicket <= cumulative) {
          winner = b;
          break;
        }
      }

      // Credit winner's UserVaultDO (minus 5% arena rake)
      const winnerVault = this.env.USER_VAULT.get(this.env.USER_VAULT.idFromName(winner.player_id));
      await winnerVault.creditPvpWin(totalTonPot * 0.95, Math.floor(totalStarsPot * 0.95));

      this.sql.exec("UPDATE round_state SET status = 'roundResolving' WHERE id = 1");

      // Broadcast resolution seed so every Flutter client runs the identical 8-second puck flight locally!
      this.broadcast({
        type: "round_resolving",
        roundId: state.round_id,
        winnerPlayerId: winner.player_id,
        winnerUsername: winner.username,
        payoutTon: totalTonPot * 0.95,
        payoutStars: Math.floor(totalStarsPot * 0.95),
        revealedServerSeed: state.server_seed,
        physicsSeed: state.round_id, // Passed to TerritoryPhysicsService.simulateAirHockeyFlight
      });

      // Schedule next round reset after 10 seconds (8s puck animation + 2s celebration)
      await this.ctx.storage.setAlarm(Date.now() + 10000);
    } else if (state.status === "roundResolving") {
      // Reset for next round
      const nextSeed = generateRandomSeedHex(32);
      const nextHash = await sha256Hex(nextSeed);
      this.sql.exec("DELETE FROM active_bets");
      this.sql.exec(
        "UPDATE round_state SET round_id = round_id + 1, status = 'waitingForPlayers', server_seed = ?, server_seed_hash = ?, closes_at_ms = 0 WHERE id = 1",
        nextSeed,
        nextHash
      );
      this.broadcast(this.getSnapshotPayload());
    }
  }

  private getSnapshotPayload() {
    const state = this.sql
      .exec<{ round_id: number; status: string; server_seed_hash: string; closes_at_ms: number }>(
        "SELECT round_id, status, server_seed_hash, closes_at_ms FROM round_state WHERE id = 1"
      )
      .one();

    const bets = this.sql.exec<PlayerBetRow>("SELECT * FROM active_bets").toArray();
    const totalPotTon = bets.reduce((s, b) => s + b.ton_bet, 0);
    const totalPotStars = bets.reduce((s, b) => s + b.stars_bet, 0);

    return {
      type: "round_state",
      roundId: state.round_id,
      status: state.status,
      serverSeedHash: state.server_seed_hash,
      timeRemainingMs: state.closes_at_ms > 0 ? Math.max(0, state.closes_at_ms - Date.now()) : 15000,
      totalPotTon,
      totalPotStars,
      bets,
    };
  }

  private broadcast(payload: any) {
    const msg = JSON.stringify(payload);
    for (const ws of this.ctx.getWebSockets()) {
      try {
        ws.send(msg);
      } catch (_) {}
    }
  }
}