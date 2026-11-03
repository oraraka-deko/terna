import { Env } from "./index";

export interface DepositRequest {
  userId: string;
  amountTon: number;
}

export interface VerifyTonDepositParams {
  userId: string;
  depositId: string;
  boc?: string;
  userWalletAddress?: string;
  amountTon: number;
}

export interface StarsInvoiceParams {
  userId: string;
  starsAmount: number;
}

export interface WithdrawParams {
  userId: string;
  currency: "ton" | "stars";
  amount: number;
  destination: string;
}

export class PaymentService {
  /**
   * Helper: Retrieve current deposit destination hot-wallet address from D1 database system_config,
   * with fallback to Cloudflare worker environment variables / secrets.
   */
  static async getTreasuryAddress(env: Env): Promise<string> {
    if (env.GLOBAL_DB) {
      try {
        const row = await env.GLOBAL_DB.prepare(
          "SELECT value FROM system_config WHERE key = 'treasury_wallet_address'"
        ).first<{ value: string }>();
        if (row && row.value && row.value.trim().length > 10) {
          return row.value.trim();
        }
      } catch (err) {
        console.warn("[PaymentService] Could not read treasury_wallet_address from D1:", err);
      }
    }

    return (
      env.TON_TREASURY_ADDRESS ||
      env.DEFAULT_TON_TREASURY_ADDRESS ||
      "UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA_xxx"
    );
  }

  /**
   * 0. GET WALLET CONFIGURATION
   */
  static async getWalletConfig(env: Env) {
    const depositAddress = await this.getTreasuryAddress(env);
    const isTestnet = (env.TONCENTER_NETWORK || "mainnet").toLowerCase() === "testnet";

    let minDepositTon = 0.1;
    let minDepositStars = 10;

    if (env.GLOBAL_DB) {
      try {
        const tonRow = await env.GLOBAL_DB.prepare("SELECT value FROM system_config WHERE key = 'min_deposit_ton'").first<{ value: string }>();
        if (tonRow) minDepositTon = parseFloat(tonRow.value) || 0.1;

        const starsRow = await env.GLOBAL_DB.prepare("SELECT value FROM system_config WHERE key = 'min_deposit_stars'").first<{ value: string }>();
        if (starsRow) minDepositStars = parseInt(starsRow.value, 10) || 10;
      } catch (_) {}
    }

    return {
      depositAddress,
      minDepositTon,
      minDepositStars,
      isTestnet,
      network: isTestnet ? "testnet" : "mainnet",
    };
  }

  /**
   * 1. CREATE TON DEPOSIT REQUEST
   * Generates a unique transaction identifier, standard memo comment, and pre-encoded binary payload
   */
  static async createTonDepositRequest(params: DepositRequest, env: Env) {
    const depositId = `dep_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const comment = `TERNA_${depositId}`;
    const depositAddress = await this.getTreasuryAddress(env);
    const now = Date.now();

    // Standard TON comment payload: 4 null bytes (0x00000000) followed by UTF-8 comment string
    const commentBytes = new TextEncoder().encode(comment);
    const payloadBytes = new Uint8Array(4 + commentBytes.length);
    payloadBytes.set(commentBytes, 4);
    // Convert to base64
    let binary = "";
    for (let i = 0; i < payloadBytes.byteLength; i++) {
      binary += String.fromCharCode(payloadBytes[i]);
    }
    const payloadBase64 = btoa(binary);

    const nanoAmount = Math.round(params.amountTon * 1e9).toString();

    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare(
          `INSERT INTO ton_deposits (id, user_id, amount_ton, comment, status, created_at)
           VALUES (?, ?, ?, ?, 'PENDING', ?)`
        ).bind(depositId, params.userId, params.amountTon, comment, now),
        env.GLOBAL_DB.prepare(
          `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, status, comment, created_at)
           VALUES (?, ?, 'DEPOSIT_TON', ?, 'PENDING', ?, ?)`
        ).bind(depositId, params.userId, params.amountTon, comment, now),
      ]);
    }

    return {
      depositId,
      comment,
      depositAddress,
      payload: payloadBase64,
      amountTon: params.amountTon,
      nanoAmount,
      status: "PENDING",
    };
  }

  /**
   * 2. VERIFY TON DEPOSIT
   * Verifies signed BOC or calls TonCenter API to inspect recent blocks on chain
   */
  static async verifyTonDeposit(params: VerifyTonDepositParams, env: Env) {
    const { userId, depositId, boc, userWalletAddress, amountTon } = params;
    const depositAddress = await this.getTreasuryAddress(env);
    const expectedComment = `TERNA_${depositId}`;
    const expectedNano = Math.round(amountTon * 1e9);

    let verified = false;
    let txHash: string | undefined = boc ? `boc_${boc.substring(0, 16)}...` : undefined;

    // Check with TonCenter API if network or API key is available
    try {
      const baseUrl = env.TONCENTER_BASE_URL || (env.TONCENTER_NETWORK === "testnet" ? "https://testnet.toncenter.com/api/v2" : "https://toncenter.com/api/v2");
      const url = new URL(`${baseUrl}/getTransactions`);
      url.searchParams.set("address", depositAddress);
      url.searchParams.set("limit", "15");

      const headers: Record<string, string> = {};
      if (env.TONCENTER_API_KEY) {
        headers["X-API-Key"] = env.TONCENTER_API_KEY;
      }

      const resp = await fetch(url.toString(), { headers });
      if (resp.ok) {
        const data = (await resp.json()) as any;
        if (data && data.ok && Array.isArray(data.result)) {
          for (const tx of data.result) {
            const inMsg = tx.in_msg;
            if (!inMsg) continue;
            const valueNano = Number(inMsg.value || 0);
            const msgComment = inMsg.message || "";

            const commentMatches = expectedComment && (msgComment.includes(expectedComment) || msgComment.includes(depositId));
            const senderMatches =
              userWalletAddress &&
              inMsg.source &&
              (inMsg.source.toLowerCase() === userWalletAddress.toLowerCase() ||
                inMsg.source.includes(userWalletAddress.slice(-8)));
            const amountMatches = Math.abs(valueNano - expectedNano) <= 0.05 * 1e9; // 0.05 TON tolerance for gas

            if (commentMatches || (senderMatches && amountMatches)) {
              verified = true;
              txHash = tx.transaction_id?.hash || `${tx.utime}_${tx.data}`;
              break;
            }
          }
        }
      }
    } catch (err) {
      console.warn("[PaymentService] TonCenter query error:", err);
    }

    // Prevent replay attacks
    if (verified && txHash && env.GLOBAL_DB) {
      const existing = await env.GLOBAL_DB.prepare(
        "SELECT id FROM ton_deposits WHERE tx_hash = ? AND status = 'CONFIRMED' LIMIT 1"
      ).bind(txHash).first();
      if (existing) {
        return {
          verified: false,
          message: "Transaction has already been credited",
        };
      }
    }

    if (!verified) {
      return {
        verified: false,
        message: "Pending block confirmation. Please wait a few seconds and retry.",
      };
    }

    const now = Date.now();
    // Atomically credit user's SQLite vault
    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));
    const { tonBalance } = await vault.depositTon(amountTon, txHash);

    // Confirm in D1 database
    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare(
          `UPDATE ton_deposits 
           SET status = 'CONFIRMED', tx_hash = ?, boc = ?, confirmed_at = ? 
           WHERE id = ?`
        ).bind(txHash || null, boc || null, now, depositId),
        env.GLOBAL_DB.prepare(
          `UPDATE ledger_transactions 
           SET status = 'CONFIRMED', tx_hash = ?, boc = ?, confirmed_at = ? 
           WHERE id = ?`
        ).bind(txHash || null, boc || null, now, depositId),
      ]);
    }

    return {
      verified: true,
      depositId,
      txHash,
      tonBalance,
      message: "✓ Transaction successfully verified and credited!",
    };
  }

  /**
   * 3. CREATE TELEGRAM STARS INVOICE
   * Integrates with Telegram Bot API createInvoiceLink for XTR Stars
   */
  static async createStarsInvoice(params: StarsInvoiceParams, env: Env) {
    const { userId, starsAmount } = params;
    const invoiceId = `stars_inv_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const now = Date.now();

    let invoiceLink = "";
    let botToken = env.TELEGRAM_BOT_TOKEN;

    if (!botToken && env.GLOBAL_DB) {
      try {
        const row = await env.GLOBAL_DB.prepare("SELECT value FROM system_config WHERE key = 'telegram_bot_token'").first<{ value: string }>();
        if (row) botToken = row.value;
      } catch (_) {}
    }

    if (botToken) {
      try {
        const title = `${starsAmount} Telegram Stars Deposit`;
        const description = `Top up ${starsAmount} Stars into your in-app gaming wallet`;
        const payload = JSON.stringify({ invoiceId, userId, starsAmount, time: now });

        const resp = await fetch(`https://api.telegram.org/bot${botToken}/createInvoiceLink`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title,
            description,
            payload,
            currency: "XTR",
            prices: [{ label: `${starsAmount} Stars`, amount: starsAmount }],
          }),
        });
        const data = (await resp.json()) as any;
        if (data.ok && data.result) {
          invoiceLink = data.result;
        } else {
          console.error("[PaymentService] Telegram createInvoiceLink error:", data);
        }
      } catch (err) {
        console.warn("[PaymentService] Telegram API fetch error:", err);
      }
    }

    // Record in D1
    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare(
          `INSERT INTO stars_invoices (id, user_id, stars_amount, invoice_link, status, created_at)
           VALUES (?, ?, ?, ?, 'PENDING', ?)`
        ).bind(invoiceId, userId, starsAmount, invoiceLink, now),
        env.GLOBAL_DB.prepare(
          `INSERT INTO ledger_transactions (id, user_id, type, amount_stars, status, comment, created_at)
           VALUES (?, ?, 'DEPOSIT_STARS', ?, 'PENDING', ?, ?)`
        ).bind(invoiceId, userId, starsAmount, `Stars Invoice ${invoiceId}`, now),
      ]);
    }

    return {
      ok: true,
      invoiceId,
      invoiceLink,
      starsAmount,
      status: "PENDING",
    };
  }

  /**
   * 4. CHECK STARS INVOICE STATUS
   */
  static async getStarsInvoiceStatus(invoiceId: string, env: Env) {
    if (!env.GLOBAL_DB) return { ok: true, paid: false, status: "NOT_FOUND" };

    const row = await env.GLOBAL_DB.prepare("SELECT * FROM stars_invoices WHERE id = ?").bind(invoiceId).first<any>();
    if (!row) return { ok: true, paid: false, status: "NOT_FOUND" };

    const isPaid = row.status === "CONFIRMED";
    return {
      ok: true,
      paid: isPaid,
      status: row.status,
      starsAmount: row.stars_amount,
    };
  }

  /**
   * 5. CONFIRM TELEGRAM STARS PAYMENT
   */
  static async confirmStarsPayment(params: { userId: string; starsAmount: number; invoiceId: string }, env: Env) {
    const { userId, starsAmount, invoiceId } = params;
    const now = Date.now();

    // Check if already confirmed in D1
    if (env.GLOBAL_DB) {
      const existing = await env.GLOBAL_DB.prepare("SELECT status FROM stars_invoices WHERE id = ?").bind(invoiceId).first<any>();
      if (existing && existing.status === "CONFIRMED") {
        const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));
        const state = await vault.getState();
        return { success: true, alreadyProcessed: true, starsBalance: state.starsBalance };
      }
    }

    // Credit user vault
    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));
    const { starsBalance } = await vault.creditStars(starsAmount);

    // Update D1
    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare("UPDATE stars_invoices SET status = 'CONFIRMED', confirmed_at = ? WHERE id = ?").bind(now, invoiceId),
        env.GLOBAL_DB.prepare("UPDATE ledger_transactions SET status = 'CONFIRMED', confirmed_at = ? WHERE id = ?").bind(now, invoiceId),
      ]);
    }

    return {
      success: true,
      alreadyProcessed: false,
      starsBalance,
    };
  }

  /**
   * 6. REQUEST WITHDRAWAL (TON OR STARS)
   */
  static async requestWithdrawal(params: WithdrawParams, env: Env) {
    const { userId, currency, amount, destination } = params;
    const withdrawalId = `wth_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const now = Date.now();

    const vault = env.USER_VAULT.get(env.USER_VAULT.idFromName(userId));

    // Debit currency from vault
    const { tonBalance, starsBalance } = await vault.debitCurrency(currency, amount);

    // Record in D1
    if (env.GLOBAL_DB) {
      await env.GLOBAL_DB.batch([
        env.GLOBAL_DB.prepare(
          `INSERT INTO withdrawals (id, user_id, currency, amount, destination, status, created_at)
           VALUES (?, ?, ?, ?, ?, 'PENDING_HOLD', ?)`
        ).bind(withdrawalId, userId, currency.toUpperCase(), amount, destination, now),
        env.GLOBAL_DB.prepare(
          `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, amount_stars, status, comment, details, created_at)
           VALUES (?, ?, ?, ?, ?, 'PENDING', ?, ?, ?)`
        ).bind(
          withdrawalId,
          userId,
          currency === "ton" ? "WITHDRAW_TON" : "WITHDRAW_STARS",
          currency === "ton" ? -amount : 0,
          currency === "stars" ? -Math.round(amount) : 0,
          `Withdrawal to ${destination}`,
          JSON.stringify({ destination, currency }),
          now
        ),
      ]);
    }

    return {
      success: true,
      withdrawalId,
      status: "PENDING_HOLD",
      tonBalance,
      starsBalance,
    };
  }
}
