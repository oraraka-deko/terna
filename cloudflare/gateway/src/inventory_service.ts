import { Env } from "./index";

export class InventoryService {
  /**
   * 1. GET USER INVENTORY
   */
  static async getUserInventory(userId: string, env: Env) {
    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));
    const state = await vault.getState();
    return { gifts: state.gifts };
  }

  /**
   * 2. BUY GIFT FROM SHOP CATALOG
   */
  static async buyShopGift(
    params: { userId: string; giftId: string; currency: "ton" | "stars" },
    env: Env
  ) {
    const { userId, giftId, currency } = params;

    // Fetch gift item details from D1
    if (!env.GLOBAL_DB) throw new Error("Database not connected");
    const gift = await env.GLOBAL_DB.prepare("SELECT * FROM shop_gifts WHERE gift_id = ?").bind(giftId).first<any>();
    if (!gift) throw new Error("Gift not found in shop catalog");

    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));

    // Debit cost
    const cost = currency === "ton" ? gift.price_gram : gift.price_stars;
    await vault.debitCurrency(currency, cost);

    // Mint gift into UserVaultDO
    const instanceId = `gft_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const addedGift = await vault.addGift({
      instanceId,
      giftId: gift.gift_id,
      name: gift.name,
      priceStars: gift.price_stars,
      valuation: gift.price_gram,
    });

    const now = Date.now();
    // Record in D1 user_inventory and ledger
    await env.GLOBAL_DB.batch([
      env.GLOBAL_DB.prepare(
        `INSERT INTO user_inventory (instance_id, user_id, gift_id, name, model_name, backdrop_color, edge_color, symbol_name, rarity, valuation, price_stars, acquired_at)
         VALUES (?, ?, ?, ?, 'Standard Edition', '#8b5cf6', '#3b82f6', 'Telegram Star', 0, ?, ?, ?)`
      ).bind(instanceId, userId, gift.gift_id, gift.name, gift.price_gram, gift.price_stars, now),
      env.GLOBAL_DB.prepare(
        `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, amount_stars, status, comment, details, created_at, confirmed_at)
         VALUES (?, ?, 'GIFT_BUY', ?, ?, 'CONFIRMED', ?, ?, ?, ?)`
      ).bind(
        `tx_buy_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        userId,
        currency === "ton" ? -cost : 0,
        currency === "stars" ? -Math.round(cost) : 0,
        `Purchased gift: ${gift.name}`,
        JSON.stringify({ giftId, instanceId, currency, cost }),
        now,
        now
      ),
    ]);

    const state = await vault.getState();
    return {
      success: true,
      gift: addedGift,
      tonBalance: state.tonBalance,
      starsBalance: state.starsBalance,
    };
  }

  /**
   * 3. SELL GIFT FOR TON OR STARS AT VALUATION
   */
  static async sellUserGift(
    params: { userId: string; giftInstanceId: string; currency: "ton" | "stars" },
    env: Env
  ) {
    const { userId, giftInstanceId, currency } = params;
    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));

    // Remove gift from vault
    const removed = await vault.removeGift(giftInstanceId);
    if (!removed) throw new Error("Gift not found in inventory");

    // Credit proceeds based on valuation / priceStars (e.g. 80% buyback floor price)
    const proceeds =
      currency === "ton"
        ? +(removed.valuation ? removed.valuation * 0.8 : (removed.price_stars * 0.0086 * 0.8)).toFixed(3)
        : Math.round(removed.price_stars * 0.8);

    await vault.creditCurrency(currency, proceeds);

    const now = Date.now();
    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare("DELETE FROM user_inventory WHERE instance_id = ?").bind(giftInstanceId),
        env.GLOBAL_DB.prepare(
          `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, amount_stars, status, comment, details, created_at, confirmed_at)
           VALUES (?, ?, 'GIFT_SELL', ?, ?, 'CONFIRMED', ?, ?, ?, ?)`
        ).bind(
          `tx_sell_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
          userId,
          currency === "ton" ? proceeds : 0,
          currency === "stars" ? proceeds : 0,
          `Sold gift: ${removed.name}`,
          JSON.stringify({ giftInstanceId, giftId: removed.gift_id, currency, proceeds }),
          now,
          now
        ),
      ]);
    }

    const state = await vault.getState();
    return {
      success: true,
      soldGift: removed,
      proceeds,
      tonBalance: state.tonBalance,
      starsBalance: state.starsBalance,
    };
  }

  /**
   * 4. GRANT GIFT TO USER (Admin / Reward / Drops)
   */
  static async grantGift(
    params: {
      userId: string;
      giftId: string;
      name: string;
      priceStars: number;
      valuation?: number;
    },
    env: Env
  ) {
    const { userId, giftId, name, priceStars, valuation } = params;
    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));

    const instanceId = `gft_grant_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const added = await vault.addGift({
      instanceId,
      giftId,
      name,
      priceStars,
      valuation: valuation || +(priceStars * 0.0086).toFixed(3),
    });

    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.prepare(
        `INSERT INTO user_inventory (instance_id, user_id, gift_id, name, valuation, price_stars, acquired_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(instanceId, userId, giftId, name, added.valuation || 0, priceStars, Date.now())
        .run();
    }

    return added;
  }
}

