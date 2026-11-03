import { DurableObject } from "cloudflare:workers";
import { computeProvablyFairRoll, generateRandomSeedHex, sha256Hex } from "./crypto";
import {
  deriveDiscreteOutcome,
  derivePlinkoPath,
  deriveRoulettePocket,
  deriveHigherLowerDeck,
  generateMinePositionsUnbiased,
  generateTowerBoardUnbiased,
  resolveUpgradeOutcome,
  createEdgePfReceipt,
  CardDefinition,
} from "./provably_fair";

export interface GiftRecord {
  instance_id: string;
  gift_id: string;
  name: string;
  price_stars: number;
  model_name?: string;
  backdrop_color?: string;
  edge_color?: string;
  symbol_name?: string;
  rarity?: number;
  valuation?: number;
  acquired_at?: number;
}

export class UserVaultDO extends DurableObject {
  sql: SqlStorage;
  env: any;

  constructor(ctx: DurableObjectState, env: any) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.env = env;

    // 0ms embedded SQLite schema for this specific player
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS wallet (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        ton_nano INTEGER NOT NULL DEFAULT 5000000000, -- 5.0 TON default demo
        stars INTEGER NOT NULL DEFAULT 500,
        server_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL,
        client_seed TEXT NOT NULL DEFAULT 'terna_client_v1',
        nonce INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS gifts (
        instance_id TEXT PRIMARY KEY,
        gift_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price_stars INTEGER NOT NULL,
        model_name TEXT DEFAULT 'Standard Edition',
        backdrop_color TEXT DEFAULT '#8b5cf6',
        edge_color TEXT DEFAULT '#3b82f6',
        symbol_name TEXT DEFAULT 'Telegram Star',
        rarity REAL DEFAULT 0,
        valuation REAL DEFAULT 0,
        acquired_at INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS tower_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        bet_raw INTEGER NOT NULL,
        currency TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        current_row INTEGER NOT NULL,
        trap_matrix_json TEXT NOT NULL,
        server_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS higher_lower_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        bet_raw INTEGER NOT NULL,
        currency TEXT NOT NULL,
        current_multiplier REAL NOT NULL DEFAULT 1.0,
        streak INTEGER NOT NULL DEFAULT 0,
        active_rank INTEGER NOT NULL,
        active_suit TEXT NOT NULL,
        active_higher_odds REAL NOT NULL DEFAULT 1.0,
        active_lower_odds REAL NOT NULL DEFAULT 1.0,
        deck_json TEXT NOT NULL,
        server_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS mines_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        bet_raw INTEGER NOT NULL,
        currency TEXT NOT NULL,
        mine_count INTEGER NOT NULL,
        revealed_json TEXT NOT NULL DEFAULT '[]',
        mine_positions_json TEXT NOT NULL,
        server_seed TEXT NOT NULL,
        server_seed_hash TEXT NOT NULL
      );
    `);
  }

  private async ensureInitialized() {
    const existing = this.sql.exec("SELECT id FROM wallet WHERE id = 1").toArray();
    if (existing.length === 0) {
      const seed = generateRandomSeedHex(32);
      const seedHash = await sha256Hex(seed);
      this.sql.exec(
        "INSERT INTO wallet (id, ton_nano, stars, server_seed, server_seed_hash) VALUES (1, 5000000000, 500, ?, ?)",
        seed,
        seedHash
      );
    }
  }

  // 1. GET STATE (Balances, Inventory Gifts, Current Provably Fair Seed Hash)
  async getState() {
    await this.ensureInitialized();
    const wallet = this.sql
      .exec<{ ton_nano: number; stars: number; server_seed_hash: string; client_seed: string; nonce: number }>(
        "SELECT ton_nano, stars, server_seed_hash, client_seed, nonce FROM wallet WHERE id = 1"
      )
      .one();

    const gifts = this.sql
      .exec<GiftRecord>(
        "SELECT instance_id, gift_id, name, price_stars, model_name, backdrop_color, edge_color, symbol_name, rarity, valuation, acquired_at FROM gifts"
      )
      .toArray();

    return {
      tonBalance: wallet.ton_nano / 1e9,
      starsBalance: wallet.stars,
      serverSeedHash: wallet.server_seed_hash,
      clientSeed: wallet.client_seed,
      nonce: wallet.nonce,
      gifts,
    };
  }

  // 2. PAYMENT METHODS (Deposits, Credits, Withdrawals)
  async depositTon(amountTon: number, txHash?: string): Promise<{ tonBalance: number }> {
    await this.ensureInitialized();
    const nano = Math.round(amountTon * 1e9);
    return this.ctx.storage.transactionSync(() => {
      this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ? WHERE id = 1", nano);
      const w = this.sql.exec<{ ton_nano: number }>("SELECT ton_nano FROM wallet WHERE id = 1").one();
      return { tonBalance: w.ton_nano / 1e9 };
    });
  }

  async creditStars(starsAmount: number): Promise<{ starsBalance: number }> {
    await this.ensureInitialized();
    const stars = Math.round(starsAmount);
    return this.ctx.storage.transactionSync(() => {
      this.sql.exec("UPDATE wallet SET stars = stars + ? WHERE id = 1", stars);
      const w = this.sql.exec<{ stars: number }>("SELECT stars FROM wallet WHERE id = 1").one();
      return { starsBalance: w.stars };
    });
  }

  async debitCurrency(currency: "ton" | "stars", amount: number): Promise<{ tonBalance: number; starsBalance: number }> {
    await this.ensureInitialized();
    return this.ctx.storage.transactionSync(() => {
      const w = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      if (currency === "ton") {
        const nano = Math.round(amount * 1e9);
        if (w.ton_nano < nano) throw new Error("Insufficient TON balance");
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano - ? WHERE id = 1", nano);
      } else {
        const stars = Math.round(amount);
        if (w.stars < stars) throw new Error("Insufficient Stars balance");
        this.sql.exec("UPDATE wallet SET stars = stars - ? WHERE id = 1", stars);
      }
      const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return { tonBalance: updated.ton_nano / 1e9, starsBalance: updated.stars };
    });
  }

  async creditCurrency(currency: "ton" | "stars", amount: number): Promise<{ tonBalance: number; starsBalance: number }> {
    await this.ensureInitialized();
    return this.ctx.storage.transactionSync(() => {
      if (currency === "ton") {
        const nano = Math.round(amount * 1e9);
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ? WHERE id = 1", nano);
      } else {
        const stars = Math.round(amount);
        this.sql.exec("UPDATE wallet SET stars = stars + ? WHERE id = 1", stars);
      }
      const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return { tonBalance: updated.ton_nano / 1e9, starsBalance: updated.stars };
    });
  }

  // 3. INVENTORY & GIFT METHODS
  async addGift(gift: {
    instanceId?: string;
    giftId: string;
    name: string;
    priceStars: number;
    modelName?: string;
    backdropColor?: string;
    edgeColor?: string;
    symbolName?: string;
    rarity?: number;
    valuation?: number;
  }): Promise<GiftRecord> {
    await this.ensureInitialized();
    const instanceId = gift.instanceId || `gft_${Date.now()}_${generateRandomSeedHex(4)}`;
    const record: GiftRecord = {
      instance_id: instanceId,
      gift_id: gift.giftId,
      name: gift.name,
      price_stars: gift.priceStars,
      model_name: gift.modelName || "Standard Edition",
      backdrop_color: gift.backdropColor || "#8b5cf6",
      edge_color: gift.edgeColor || "#3b82f6",
      symbol_name: gift.symbolName || "Telegram Star",
      rarity: gift.rarity || 0,
      valuation: gift.valuation || +(gift.priceStars * 0.0086).toFixed(3),
      acquired_at: Date.now(),
    };

    this.sql.exec(
      `INSERT OR REPLACE INTO gifts 
       (instance_id, gift_id, name, price_stars, model_name, backdrop_color, edge_color, symbol_name, rarity, valuation, acquired_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      record.instance_id,
      record.gift_id,
      record.name,
      record.price_stars,
      record.model_name,
      record.backdrop_color,
      record.edge_color,
      record.symbol_name,
      record.rarity,
      record.valuation,
      record.acquired_at
    );

    return record;
  }

  async removeGift(instanceId: string): Promise<GiftRecord | null> {
    await this.ensureInitialized();
    const rows = this.sql.exec<GiftRecord>("SELECT * FROM gifts WHERE instance_id = ?", instanceId).toArray();
    if (rows.length === 0) return null;
    this.sql.exec("DELETE FROM gifts WHERE instance_id = ?", instanceId);
    return rows[0];
  }

  // 4. P2P SENDING GIFTS & CURRENCY TRANSFERS
  async transferGiftOut(instanceId: string): Promise<GiftRecord> {
    await this.ensureInitialized();
    const gift = await this.removeGift(instanceId);
    if (!gift) throw new Error("Gift not found in sender inventory");
    return gift;
  }

  async transferGiftIn(gift: GiftRecord): Promise<GiftRecord> {
    await this.ensureInitialized();
    return this.addGift({
      instanceId: `trf_${Date.now()}_${generateRandomSeedHex(4)}`,
      giftId: gift.gift_id,
      name: gift.name,
      priceStars: gift.price_stars,
      modelName: gift.model_name,
      backdropColor: gift.backdrop_color,
      edgeColor: gift.edge_color,
      symbolName: gift.symbol_name,
      rarity: gift.rarity,
      valuation: gift.valuation,
    });
  }

  async transferCurrencyOut(
    currency: "ton" | "stars",
    amount: number,
    fee: number
  ): Promise<{ tonBalance: number; starsBalance: number }> {
    await this.ensureInitialized();
    return this.ctx.storage.transactionSync(() => {
      const w = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      if (currency === "ton") {
        const totalNano = Math.round((amount + fee) * 1e9);
        if (w.ton_nano < totalNano) throw new Error("Insufficient TON for transfer + fee");
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano - ? WHERE id = 1", totalNano);
      } else {
        const totalStars = Math.round(amount + fee);
        if (w.stars < totalStars) throw new Error("Insufficient Stars for transfer + fee");
        this.sql.exec("UPDATE wallet SET stars = stars - ? WHERE id = 1", totalStars);
      }
      const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return { tonBalance: updated.ton_nano / 1e9, starsBalance: updated.stars };
    });
  }

  async transferCurrencyIn(currency: "ton" | "stars", amount: number): Promise<{ tonBalance: number; starsBalance: number }> {
    return this.creditCurrency(currency, amount);
  }

  // 5. PVP TERRITORY ROOM RPC HOOKS
  async deductPvpBet(currency: "ton" | "stars", amount: number): Promise<void> {
    await this.debitCurrency(currency, amount);
  }

  async creditPvpWin(tonAmount: number, starsAmount: number): Promise<void> {
    await this.ensureInitialized();
    const nano = Math.round(tonAmount * 1e9);
    const stars = Math.round(starsAmount);
    this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ?, stars = stars + ? WHERE id = 1", nano, stars);
  }

  // 6. PLAY UPGRADE WHEEL
  async playUpgrade(params: {
    additionalTon: number;
    additionalStars: number;
    selectedGiftInstanceIds: string[];
    targetGift: { giftId: string; name: string; priceStars: number };
  }) {
    await this.ensureInitialized();
    const tonNanoBet = Math.round((params.additionalTon || 0) * 1e9);
    const starsBet = Math.round(params.additionalStars || 0);

    const deducted = this.sql.exec<{ ton_nano: number; stars: number; server_seed: string; client_seed: string; nonce: number }>(
      "UPDATE wallet SET ton_nano = ton_nano - ?, stars = stars - ?, nonce = nonce + 1 WHERE id = 1 AND ton_nano >= ? AND stars >= ? RETURNING ton_nano, stars, server_seed, client_seed, nonce",
      tonNanoBet,
      starsBet,
      tonNanoBet,
      starsBet
    ).toArray();

    if (deducted.length === 0) throw new Error("Insufficient balance for Upgrade");
    const w = deducted[0];

    let giftStarsTotal = 0;
    for (const instId of params.selectedGiftInstanceIds || []) {
      const rows = this.sql
        .exec<{ price_stars: number }>("SELECT price_stars FROM gifts WHERE instance_id = ?", instId)
        .toArray();
      if (rows.length === 0) throw new Error(`Gift ${instId} not found in inventory`);
      giftStarsTotal += rows[0].price_stars;
      this.sql.exec("DELETE FROM gifts WHERE instance_id = ?", instId);
    }

    const totalBetStarsEquiv = giftStarsTotal + starsBet + (tonNanoBet / 1e9) * 100.0;
    if (totalBetStarsEquiv <= 0) throw new Error("Bet must be greater than 0");

    const winChancePercent = Math.min(95.0, (totalBetStarsEquiv / params.targetGift.priceStars) * 95.0);

    const outcome = await resolveUpgradeOutcome(w.server_seed, w.client_seed, w.nonce, winChancePercent);

    const nextServerSeed = generateRandomSeedHex(32);
    const nextServerSeedHash = await sha256Hex(nextServerSeed);

    this.sql.exec(
      "UPDATE wallet SET server_seed = ?, server_seed_hash = ? WHERE id = 1",
      nextServerSeed,
      nextServerSeedHash
    );

    let grantedGift: GiftRecord | null = null;
    if (outcome.won) {
      const instanceId = `gft_${Date.now()}_${generateRandomSeedHex(4)}`;
      this.sql.exec(
        "INSERT INTO gifts (instance_id, gift_id, name, price_stars) VALUES (?, ?, ?, ?)",
        instanceId,
        params.targetGift.giftId,
        params.targetGift.name,
        params.targetGift.priceStars
      );
      grantedGift = {
        instance_id: instanceId,
        gift_id: params.targetGift.giftId,
        name: params.targetGift.name,
        price_stars: params.targetGift.priceStars,
      };
    }

    const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
    return {
      won: outcome.won,
      rollPercentile: outcome.rollPercentile,
      winChancePercent,
      targetAngleDeg: outcome.targetAngleDeg,
      grantedGift,
      revealedServerSeed: w.server_seed,
      nextServerSeedHash,
      tonBalance: updated.ton_nano / 1e9,
      starsBalance: updated.stars,
    };
  }

  // 7. PLAY PLINKO
  async playPlinko(params: { currency: "ton" | "stars"; betAmount: number; risk: "low" | "medium" | "high" }) {
    await this.ensureInitialized();
    const bet = Number(params.betAmount ?? (params as any).bet ?? 0);
    if (!bet || bet <= 0) throw new Error("Invalid bet amount");
    const betNano = params.currency === "ton" ? Math.round(bet * 1e9) : Math.round(bet);

    const deducted = this.sql.exec<{ ton_nano: number; stars: number; server_seed: string; client_seed: string; nonce: number }>(
      params.currency === "ton"
        ? "UPDATE wallet SET ton_nano = ton_nano - ?, nonce = nonce + 1 WHERE id = 1 AND ton_nano >= ? RETURNING ton_nano, stars, server_seed, client_seed, nonce"
        : "UPDATE wallet SET stars = stars - ?, nonce = nonce + 1 WHERE id = 1 AND stars >= ? RETURNING ton_nano, stars, server_seed, client_seed, nonce",
      betNano,
      betNano
    ).toArray();

    if (deducted.length === 0) throw new Error(`Insufficient ${params.currency === "ton" ? "TON" : "Stars"}`);
    const w = deducted[0];

    const path = await derivePlinkoPath(w.server_seed, w.client_seed, w.nonce, 8, params.risk);
    const payout = bet * path.multiplier;
    const payoutRaw = params.currency === "ton" ? Math.round(payout * 1e9) : Math.round(payout);

    const nextSeed = generateRandomSeedHex(32);
    const nextHash = await sha256Hex(nextSeed);

    this.sql.exec(
      params.currency === "ton"
        ? "UPDATE wallet SET ton_nano = ton_nano + ?, server_seed = ?, server_seed_hash = ? WHERE id = 1"
        : "UPDATE wallet SET stars = stars + ?, server_seed = ?, server_seed_hash = ? WHERE id = 1",
      payoutRaw,
      nextSeed,
      nextHash
    );

    const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
    return {
      bucketIndex: path.bucketIndex,
      directions: path.directions,
      multiplier: path.multiplier,
      payout,
      revealedServerSeed: w.server_seed,
      nextServerSeedHash: nextHash,
      tonBalance: updated.ton_nano / 1e9,
      starsBalance: updated.stars,
    };
  }

  // 8. TOWER CLIMB (7 ROWS)
  async startTower(params: { currency: "ton" | "stars"; betAmount: number; difficulty: "easy" | "medium" | "master" }) {
    await this.ensureInitialized();
    const w = this.sql
      .exec<{ ton_nano: number; stars: number; client_seed: string; nonce: number }>(
        "SELECT ton_nano, stars, client_seed, nonce FROM wallet WHERE id = 1"
      )
      .one();

    const serverSeed = generateRandomSeedHex(32);
    const serverSeedHash = await sha256Hex(serverSeed);
    const trapMatrix = await generateTowerBoardUnbiased(serverSeed, w.client_seed, w.nonce, params.difficulty);

    const bet = Number(params.betAmount ?? (params as any).bet ?? 0);
    if (!bet || bet <= 0) throw new Error("Invalid bet amount");
    const betRaw = params.currency === "ton" ? Math.round(bet * 1e9) : Math.round(bet);

    return this.ctx.storage.transactionSync(() => {
      if (params.currency === "ton") {
        if (w.ton_nano < betRaw) throw new Error("Insufficient TON");
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano - ?, nonce = nonce + 1 WHERE id = 1", betRaw);
      } else {
        if (w.stars < betRaw) throw new Error("Insufficient Stars");
        this.sql.exec("UPDATE wallet SET stars = stars - ?, nonce = nonce + 1 WHERE id = 1", betRaw);
      }

      this.sql.exec(
        `INSERT OR REPLACE INTO tower_session (id, bet_raw, currency, difficulty, current_row, trap_matrix_json, server_seed, server_seed_hash)
         VALUES (1, ?, ?, ?, 0, ?, ?, ?)`,
        betRaw,
        params.currency,
        params.difficulty,
        JSON.stringify(trapMatrix),
        serverSeed,
        serverSeedHash
      );

      return { serverSeedHash, currentRow: 0 };
    });
  }

  async pickTowerTile(colIndex: number) {
    const session = this.sql
      .exec<{
        bet_raw: number;
        currency: string;
        difficulty: string;
        current_row: number;
        trap_matrix_json: string;
        server_seed: string;
      }>("SELECT * FROM tower_session WHERE id = 1")
      .toArray()[0];

    if (!session) throw new Error("No active Tower session");

    const matrix: number[][] = JSON.parse(session.trap_matrix_json);
    const currentRowTiles = matrix[session.current_row];
    const isTrap = currentRowTiles[colIndex] === 1;

    if (isTrap) {
      this.sql.exec("DELETE FROM tower_session WHERE id = 1");
      return {
        status: "busted",
        rowTiles: currentRowTiles,
        fullMatrix: matrix,
        revealedServerSeed: session.server_seed,
      };
    }

    const nextRow = session.current_row + 1;
    if (nextRow >= 7) {
      return this.cashOutTower(true);
    }

    this.sql.exec("UPDATE tower_session SET current_row = ? WHERE id = 1", nextRow);
    return {
      status: "safe",
      clearedRow: session.current_row,
      rowTiles: currentRowTiles,
      nextRow,
    };
  }

  async cashOutTower(isMaxRow = false) {
    const session = this.sql
      .exec<{
        bet_raw: number;
        currency: string;
        difficulty: string;
        current_row: number;
        trap_matrix_json: string;
        server_seed: string;
      }>("SELECT * FROM tower_session WHERE id = 1")
      .toArray()[0];

    if (!session || (session.current_row === 0 && !isMaxRow)) {
      throw new Error("Cannot cash out before clearing row 1");
    }

    const MULT_TABLE: Record<string, number[]> = {
      easy: [1.2, 1.5, 1.9, 2.4, 3.0, 3.8, 4.8],
      medium: [1.6, 2.6, 4.3, 7.1, 11.8, 19.6, 32.5],
      master: [2.4, 5.8, 14.0, 33.6, 80.6, 193.5, 464.4],
    };

    const clearedIdx = isMaxRow ? 6 : session.current_row - 1;
    const mult = MULT_TABLE[session.difficulty][clearedIdx];
    const payoutRaw = Math.round(session.bet_raw * mult);

    return this.ctx.storage.transactionSync(() => {
      if (session.currency === "ton") {
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ? WHERE id = 1", payoutRaw);
      } else {
        this.sql.exec("UPDATE wallet SET stars = stars + ? WHERE id = 1", payoutRaw);
      }
      this.sql.exec("DELETE FROM tower_session WHERE id = 1");

      const w = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return {
        status: "cashed_out",
        multiplier: mult,
        payout: session.currency === "ton" ? payoutRaw / 1e9 : payoutRaw,
        fullMatrix: JSON.parse(session.trap_matrix_json),
        revealedServerSeed: session.server_seed,
        tonBalance: w.ton_nano / 1e9,
        starsBalance: w.stars,
      };
    });
  }

  // 9. HIGHER OR LOWER GAME (PROVABLY FAIR 52-CARD DECK)
  async startHigherLower(params: { currency: "ton" | "stars"; betAmount: number }) {
    await this.ensureInitialized();
    const bet = Number(params.betAmount ?? 0);
    if (!bet || bet <= 0) throw new Error("Invalid bet amount");
    const betRaw = params.currency === "ton" ? Math.round(bet * 1e9) : Math.round(bet);

    const deducted = this.sql.exec<{ ton_nano: number; stars: number; client_seed: string; nonce: number }>(
      params.currency === "ton"
        ? "UPDATE wallet SET ton_nano = ton_nano - ?, nonce = nonce + 1 WHERE id = 1 AND ton_nano >= ? RETURNING ton_nano, stars, client_seed, nonce"
        : "UPDATE wallet SET stars = stars - ?, nonce = nonce + 1 WHERE id = 1 AND stars >= ? RETURNING ton_nano, stars, client_seed, nonce",
      betRaw,
      betRaw
    ).toArray();

    if (deducted.length === 0) throw new Error(`Insufficient ${params.currency === "ton" ? "TON" : "Stars"}`);
    const w = deducted[0];

    const serverSeed = generateRandomSeedHex(32);
    const serverSeedHash = await sha256Hex(serverSeed);
    const deck = await deriveHigherLowerDeck(serverSeed, w.client_seed, w.nonce);
    const startingCard = deck.pop()!;
    const odds = this.calculateCardOdds(startingCard.rank, deck);

    this.sql.exec(
      `INSERT OR REPLACE INTO higher_lower_session 
       (id, bet_raw, currency, current_multiplier, streak, active_rank, active_suit, active_higher_odds, active_lower_odds, deck_json, server_seed, server_seed_hash)
       VALUES (1, ?, ?, 1.0, 0, ?, ?, ?, ?, ?, ?, ?)`,
      betRaw,
      params.currency,
      startingCard.rank,
      startingCard.suit,
      odds.higherOdds,
      odds.lowerOdds,
      JSON.stringify(deck),
      serverSeed,
      serverSeedHash
    );

    return {
      serverSeedHash,
      card: startingCard,
      currentMultiplier: 1.0,
      streak: 0,
      higherOdds: odds.higherOdds,
      lowerOdds: odds.lowerOdds,
      isAce: startingCard.rank === 14,
      isTwo: startingCard.rank === 2,
      tonBalance: w.ton_nano / 1e9,
      starsBalance: w.stars,
    };
  }

  async guessHigherLower(call: "higher" | "lower" | "skip") {
    return this.ctx.storage.transactionSync(() => {
      const session = this.sql
        .exec<{
          bet_raw: number;
          currency: string;
          current_multiplier: number;
          streak: number;
          active_rank: number;
          active_suit: string;
          active_higher_odds: number;
          active_lower_odds: number;
          deck_json: string;
          server_seed: string;
        }>("SELECT * FROM higher_lower_session WHERE id = 1")
        .toArray()[0];

      if (!session) throw new Error("No active Higher or Lower session");

      const deck: CardDefinition[] = JSON.parse(session.deck_json);
      if (deck.length === 0) throw new Error("Deck is exhausted");

      const drawnCard = deck.pop()!;
      const prevRank = session.active_rank;
      const nextRank = drawnCard.rank;

      let resultStatus: "won" | "lost" | "push" | "skip" = "lost";
      let stepMultiplier = 1.0;

      if (call === "skip") {
        if (prevRank !== 14 && prevRank !== 2) throw new Error("Skip is only permitted on Ace or Two");
        resultStatus = "skip";
      } else if (nextRank === prevRank) {
        resultStatus = "push";
      } else if (call === "higher" && nextRank > prevRank) {
        resultStatus = "won";
        stepMultiplier = session.active_higher_odds;
      } else if (call === "lower" && nextRank < prevRank) {
        resultStatus = "won";
        stepMultiplier = session.active_lower_odds;
      }

      if (resultStatus === "lost") {
        this.sql.exec("DELETE FROM higher_lower_session WHERE id = 1");
        return {
          status: "lost",
          drawnCard,
          revealedServerSeed: session.server_seed,
          streak: 0,
          currentMultiplier: 0,
          payout: 0,
        };
      }

      const newStreak = resultStatus === "won" ? session.streak + 1 : session.streak;
      const newMultiplier = +(session.current_multiplier * stepMultiplier).toFixed(2);
      const newOdds = this.calculateCardOdds(drawnCard.rank, deck);

      this.sql.exec(
        `UPDATE higher_lower_session 
         SET current_multiplier = ?, streak = ?, active_rank = ?, active_suit = ?, active_higher_odds = ?, active_lower_odds = ?, deck_json = ? 
         WHERE id = 1`,
        newMultiplier,
        newStreak,
        drawnCard.rank,
        drawnCard.suit,
        newOdds.higherOdds,
        newOdds.lowerOdds,
        JSON.stringify(deck)
      );

      const payout = (session.bet_raw * newMultiplier) / (session.currency === "ton" ? 1e9 : 1);
      return {
        status: resultStatus,
        drawnCard,
        currentMultiplier: newMultiplier,
        streak: newStreak,
        payout,
        higherOdds: newOdds.higherOdds,
        lowerOdds: newOdds.lowerOdds,
        isAce: drawnCard.rank === 14,
        isTwo: drawnCard.rank === 2,
      };
    });
  }

  async cashOutHigherLower() {
    return this.ctx.storage.transactionSync(() => {
      const session = this.sql
        .exec<{
          bet_raw: number;
          currency: string;
          current_multiplier: number;
          streak: number;
          server_seed: string;
        }>("SELECT * FROM higher_lower_session WHERE id = 1")
        .toArray()[0];

      if (!session || session.streak === 0) {
        throw new Error("Cannot cash out without at least 1 winning prediction");
      }

      const payoutRaw = Math.round(session.bet_raw * session.current_multiplier);
      if (session.currency === "ton") {
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ? WHERE id = 1", payoutRaw);
      } else {
        this.sql.exec("UPDATE wallet SET stars = stars + ? WHERE id = 1", payoutRaw);
      }
      this.sql.exec("DELETE FROM higher_lower_session WHERE id = 1");

      const w = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return {
        status: "cashed_out",
        multiplier: session.current_multiplier,
        payout: session.currency === "ton" ? payoutRaw / 1e9 : payoutRaw,
        revealedServerSeed: session.server_seed,
        tonBalance: w.ton_nano / 1e9,
        starsBalance: w.stars,
      };
    });
  }

  private calculateCardOdds(rank: number, deck: CardDefinition[]) {
    if (deck.length === 0) return { higherOdds: 1.0, lowerOdds: 1.0 };
    const higherCount = deck.filter((c) => c.rank > rank).length;
    const lowerCount = deck.filter((c) => c.rank < rank).length;
    const total = deck.length;

    const higherProb = higherCount / total;
    const lowerProb = lowerCount / total;

    // 95% RTP (5% house edge)
    const higherOdds = higherProb > 0 ? Math.min(25.0, +(0.95 / higherProb).toFixed(2)) : 0;
    const lowerOdds = lowerProb > 0 ? Math.min(25.0, +(0.95 / lowerProb).toFixed(2)) : 0;

    return { higherOdds, lowerOdds };
  }

  // 10. MINES GAME (5x5 GRID)
  async startMines(params: { currency: "ton" | "stars"; betAmount: number; mineCount: number }) {
    await this.ensureInitialized();
    const w = this.sql
      .exec<{ ton_nano: number; stars: number; client_seed: string; nonce: number }>(
        "SELECT ton_nano, stars, client_seed, nonce FROM wallet WHERE id = 1"
      )
      .one();

    const serverSeed = generateRandomSeedHex(32);
    const serverSeedHash = await sha256Hex(serverSeed);
    const mineCount = Math.max(1, Math.min(24, params.mineCount || 3));
    const minePositions = await generateMinePositionsUnbiased(serverSeed, w.client_seed, w.nonce, mineCount);

    const bet = Number(params.betAmount ?? 0);
    if (!bet || bet <= 0) throw new Error("Invalid bet amount");
    const betRaw = params.currency === "ton" ? Math.round(bet * 1e9) : Math.round(bet);

    return this.ctx.storage.transactionSync(() => {
      if (params.currency === "ton") {
        if (w.ton_nano < betRaw) throw new Error("Insufficient TON");
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano - ?, nonce = nonce + 1 WHERE id = 1", betRaw);
      } else {
        if (w.stars < betRaw) throw new Error("Insufficient Stars");
        this.sql.exec("UPDATE wallet SET stars = stars - ?, nonce = nonce + 1 WHERE id = 1", betRaw);
      }

      this.sql.exec(
        `INSERT OR REPLACE INTO mines_session (id, bet_raw, currency, mine_count, revealed_json, mine_positions_json, server_seed, server_seed_hash)
         VALUES (1, ?, ?, ?, '[]', ?, ?, ?)`,
        betRaw,
        params.currency,
        mineCount,
        JSON.stringify(minePositions),
        serverSeed,
        serverSeedHash
      );

      return { serverSeedHash, mineCount };
    });
  }

  async revealMineTile(tileIndex: number) {
    const session = this.sql
      .exec<{
        bet_raw: number;
        currency: string;
        mine_count: number;
        revealed_json: string;
        mine_positions_json: string;
        server_seed: string;
      }>("SELECT * FROM mines_session WHERE id = 1")
      .toArray()[0];

    if (!session) throw new Error("No active Mines session");

    const mines: number[] = JSON.parse(session.mine_positions_json);
    const revealed: number[] = JSON.parse(session.revealed_json);

    if (revealed.includes(tileIndex)) throw new Error("Tile already revealed");
    const isMine = mines.includes(tileIndex);

    if (isMine) {
      this.sql.exec("DELETE FROM mines_session WHERE id = 1");
      return {
        status: "busted",
        minePositions: mines,
        revealedServerSeed: session.server_seed,
      };
    }

    revealed.push(tileIndex);
    const safeTilesTotal = 25 - session.mine_count;
    const gemsFound = revealed.length;

    // Calculate combinatorial multiplier
    let multiplier = 0.95;
    for (let i = 0; i < gemsFound; i++) {
      multiplier *= (25 - i) / (safeTilesTotal - i);
    }
    multiplier = +multiplier.toFixed(2);

    if (gemsFound >= safeTilesTotal) {
      return this.cashOutMines(true);
    }

    this.sql.exec("UPDATE mines_session SET revealed_json = ? WHERE id = 1", JSON.stringify(revealed));
    const payout = (session.bet_raw * multiplier) / (session.currency === "ton" ? 1e9 : 1);

    return {
      status: "safe",
      revealed,
      multiplier,
      payout,
    };
  }

  async cashOutMines(isClearAll = false) {
    const session = this.sql
      .exec<{
        bet_raw: number;
        currency: string;
        mine_count: number;
        revealed_json: string;
        mine_positions_json: string;
        server_seed: string;
      }>("SELECT * FROM mines_session WHERE id = 1")
      .toArray()[0];

    if (!session) throw new Error("No active Mines session");
    const revealed: number[] = JSON.parse(session.revealed_json);
    if (revealed.length === 0 && !isClearAll) throw new Error("Must reveal at least one safe tile before cashing out");

    const safeTilesTotal = 25 - session.mine_count;
    const gemsFound = revealed.length;

    let multiplier = 0.95;
    for (let i = 0; i < gemsFound; i++) {
      multiplier *= (25 - i) / (safeTilesTotal - i);
    }
    multiplier = +multiplier.toFixed(2);
    const payoutRaw = Math.round(session.bet_raw * multiplier);

    return this.ctx.storage.transactionSync(() => {
      if (session.currency === "ton") {
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano + ? WHERE id = 1", payoutRaw);
      } else {
        this.sql.exec("UPDATE wallet SET stars = stars + ? WHERE id = 1", payoutRaw);
      }
      this.sql.exec("DELETE FROM mines_session WHERE id = 1");

      const w = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return {
        status: "cashed_out",
        multiplier,
        payout: session.currency === "ton" ? payoutRaw / 1e9 : payoutRaw,
        minePositions: JSON.parse(session.mine_positions_json),
        revealedServerSeed: session.server_seed,
        tonBalance: w.ton_nano / 1e9,
        starsBalance: w.stars,
      };
    });
  }

  // 11. CASINO ROULETTE (38 POCKETS)
  async playRoulette(params: { currency: "ton" | "stars"; betAmount: number; bets: Record<string, number> }) {
    await this.ensureInitialized();
    const w = this.sql
      .exec<{ ton_nano: number; stars: number; server_seed: string; client_seed: string; nonce: number }>(
        "SELECT ton_nano, stars, server_seed, client_seed, nonce FROM wallet WHERE id = 1"
      )
      .one();

    const pocket = await deriveRoulettePocket(w.server_seed, w.client_seed, w.nonce);
    const nextSeed = generateRandomSeedHex(32);
    const nextHash = await sha256Hex(nextSeed);

    const totalBet = Number(params.betAmount ?? 0);
    if (!totalBet || totalBet <= 0) throw new Error("Invalid bet amount");

    // Calculate winnings based on user bets
    let totalWin = 0;
    const { pocketLabel, color } = pocket;
    for (const [betKey, betVal] of Object.entries(params.bets || {})) {
      const numVal = Number(betVal);
      if (numVal <= 0) continue;

      if (betKey === "red" && color === "red") totalWin += numVal * 2;
      else if (betKey === "black" && color === "black") totalWin += numVal * 2;
      else if (betKey === "even" && pocketLabel !== "0" && pocketLabel !== "00" && parseInt(pocketLabel, 10) % 2 === 0) totalWin += numVal * 2;
      else if (betKey === "odd" && pocketLabel !== "0" && pocketLabel !== "00" && parseInt(pocketLabel, 10) % 2 === 1) totalWin += numVal * 2;
      else if (betKey === pocketLabel) totalWin += numVal * 36;
    }

    return this.ctx.storage.transactionSync(() => {
      const betRaw = params.currency === "ton" ? Math.round(totalBet * 1e9) : Math.round(totalBet);
      const winRaw = params.currency === "ton" ? Math.round(totalWin * 1e9) : Math.round(totalWin);

      if (params.currency === "ton") {
        if (w.ton_nano < betRaw) throw new Error("Insufficient TON");
        this.sql.exec("UPDATE wallet SET ton_nano = ton_nano - ? + ?, server_seed = ?, server_seed_hash = ?, nonce = nonce + 1 WHERE id = 1", betRaw, winRaw, nextSeed, nextHash);
      } else {
        if (w.stars < betRaw) throw new Error("Insufficient Stars");
        this.sql.exec("UPDATE wallet SET stars = stars - ? + ?, server_seed = ?, server_seed_hash = ?, nonce = nonce + 1 WHERE id = 1", betRaw, winRaw, nextSeed, nextHash);
      }

      const updated = this.sql.exec<{ ton_nano: number; stars: number }>("SELECT ton_nano, stars FROM wallet WHERE id = 1").one();
      return {
        pocketIndex: pocket.pocketIndex,
        pocketLabel: pocket.pocketLabel,
        color: pocket.color,
        payout: totalWin,
        revealedServerSeed: w.server_seed,
        nextServerSeedHash: nextHash,
        tonBalance: updated.ton_nano / 1e9,
        starsBalance: updated.stars,
      };
    });
  }
}
