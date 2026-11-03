import { Env } from "./index";
import { ChatMessagePayload } from "./chat_do";

export interface TransferRequest {
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  recipientId: string;
  recipientName?: string;
  type: "GIFT" | "STARS" | "TON";
  amount?: number;
  giftInstanceId?: string;
}

export interface TransferResult {
  success: boolean;
  error?: string;
  transferData?: any;
  senderState?: any;
  recipientState?: any;
}

export async function executeChatTransfer(params: TransferRequest, env: Env): Promise<TransferResult> {
  const { senderId, senderName, senderAvatar, recipientId, recipientName, type, amount, giftInstanceId } = params;

  if (!senderId || !recipientId || senderId === recipientId) {
    return { success: false, error: "Invalid sender or recipient ID" };
  }

  const senderVault = env.USER_VAULT.get(env.USER_VAULT.idFromName(senderId));
  const recipientVault = env.USER_VAULT.get(env.USER_VAULT.idFromName(recipientId));

  try {
    let transferPayload: any = null;

    if (type === "GIFT") {
      if (!giftInstanceId) return { success: false, error: "Gift instance ID is required" };

      // 1. Atomically transfer gift out of sender vault
      const removedGift = await senderVault.transferGiftOut(giftInstanceId);

      // 2. Atomically transfer gift into recipient vault with automatic rollback
      let addedGift: any;
      try {
        addedGift = await recipientVault.transferGiftIn(removedGift);
      } catch (err) {
        // Rollback gift back to sender
        await senderVault.transferGiftIn(removedGift).catch(() => {});
        throw err;
      }

      // 3. Optional 1-star transfer fee
      const senderState = await senderVault.getState();
      const feeStars = senderState.starsBalance >= 1 ? 1 : 0;
      if (feeStars > 0) {
        await senderVault.debitCurrency("stars", feeStars).catch(() => {});
      }

      // 4. Update D1 user_inventory table
      if (env.GLOBAL_DB) {
        await env.GLOBAL_DB.batch([
          env.GLOBAL_DB.prepare("DELETE FROM user_inventory WHERE instance_id = ?").bind(giftInstanceId),
          env.GLOBAL_DB.prepare(
            `INSERT INTO user_inventory (instance_id, user_id, gift_id, name, model_name, backdrop_color, edge_color, symbol_name, rarity, valuation, price_stars, acquired_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
          ).bind(
            addedGift.instance_id,
            recipientId,
            addedGift.gift_id,
            addedGift.name,
            addedGift.model_name || "Standard Edition",
            addedGift.backdrop_color || "#8b5cf6",
            addedGift.edge_color || "#3b82f6",
            addedGift.symbol_name || "Telegram Star",
            addedGift.rarity || 0,
            addedGift.valuation || 0,
            addedGift.price_stars,
            addedGift.acquired_at || Date.now()
          ),
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, amount_stars, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_OUT', ?, ?, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_out_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            senderId,
            -(addedGift.valuation || 0),
            -feeStars,
            `Transferred gift ${addedGift.name} to @${recipientName || recipientId}`,
            JSON.stringify({ recipientId, giftId: addedGift.gift_id, giftInstanceId: addedGift.instance_id }),
            Date.now(),
            Date.now()
          ),
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, amount_stars, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_IN', ?, 0, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_in_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            recipientId,
            addedGift.valuation || 0,
            `Received gift ${addedGift.name} from @${senderName || senderId}`,
            JSON.stringify({ senderId, giftId: addedGift.gift_id, giftInstanceId: addedGift.instance_id }),
            Date.now(),
            Date.now()
          ),
        ]);
      }

      transferPayload = {
        type: "GIFT",
        giftId: addedGift.gift_id,
        giftName: addedGift.name,
        giftInstanceId: addedGift.instance_id,
        rarity: addedGift.rarity,
        fee: feeStars,
        status: "CONFIRMED",
      };
    } else if (type === "STARS") {
      const numStars = Math.floor(Number(amount) || 0);
      if (numStars < 10) return { success: false, error: "Minimum transfer is 10 Stars" };
      const fee = 1;

      // Atomically transfer out and in with rollback
      await senderVault.transferCurrencyOut("stars", numStars, fee);
      try {
        await recipientVault.transferCurrencyIn("stars", numStars);
      } catch (err) {
        await senderVault.transferCurrencyIn("stars", numStars + fee).catch(() => {});
        throw err;
      }

      // Ledger entries in D1
      if (env.GLOBAL_DB) {
        await env.GLOBAL_DB.batch([
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_stars, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_OUT', ?, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_out_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            senderId,
            -(numStars + fee),
            `Transferred ${numStars} ⭐ to @${recipientName || recipientId}`,
            JSON.stringify({ recipientId, numStars, fee }),
            Date.now(),
            Date.now()
          ),
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_stars, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_IN', ?, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_in_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            recipientId,
            numStars,
            `Received ${numStars} ⭐ from @${senderName || senderId}`,
            JSON.stringify({ senderId, numStars }),
            Date.now(),
            Date.now()
          ),
        ]);
      }

      transferPayload = {
        type: "STARS",
        amount: numStars,
        fee,
        status: "CONFIRMED",
      };
    } else if (type === "TON") {
      const numTon = +(Number(amount) || 0).toFixed(4);
      if (numTon < 0.1) return { success: false, error: "Minimum transfer is 0.1 TON" };
      const fee = 0.005;

      await senderVault.transferCurrencyOut("ton", numTon, fee);
      try {
        await recipientVault.transferCurrencyIn("ton", numTon);
      } catch (err) {
        await senderVault.transferCurrencyIn("ton", numTon + fee).catch(() => {});
        throw err;
      }

      if (env.GLOBAL_DB) {
        await env.GLOBAL_DB.batch([
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_OUT', ?, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_out_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            senderId,
            -(numTon + fee),
            `Transferred ${numTon} TON to @${recipientName || recipientId}`,
            JSON.stringify({ recipientId, numTon, fee }),
            Date.now(),
            Date.now()
          ),
          env.GLOBAL_DB.prepare(
            `INSERT INTO ledger_transactions (id, user_id, type, amount_ton, status, comment, details, created_at, confirmed_at)
             VALUES (?, ?, 'TRANSFER_IN', ?, 'CONFIRMED', ?, ?, ?, ?)`
          ).bind(
            `tx_trf_in_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
            recipientId,
            numTon,
            `Received ${numTon} TON from @${senderName || senderId}`,
            JSON.stringify({ senderId, numTon }),
            Date.now(),
            Date.now()
          ),
        ]);
      }

      transferPayload = {
        type: "TON",
        amount: numTon,
        fee,
        status: "CONFIRMED",
      };
    }

    // 5. Broadcast transfer event into ChatRoomDO
    const chatRoom = env.CHAT_ROOM.get(env.CHAT_ROOM.idFromName("global"));
    const transferMsg: ChatMessagePayload = {
      id: `tx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      scope: "DIRECT",
      channelId: "direct",
      senderId,
      senderName,
      senderAvatar,
      recipientId,
      recipientName,
      text: `Sent ${type === "GIFT" ? `Gift: ${transferPayload.giftName}` : `${transferPayload.amount} ${type === "TON" ? "TON" : "⭐"}`} to ${recipientName || recipientId}`,
      transfer: transferPayload,
      createdAt: Date.now(),
    };

    await chatRoom.broadcastMessage(transferMsg);

    const updatedSender = await senderVault.getState();
    const updatedRecipient = await recipientVault.getState();

    return {
      success: true,
      transferData: transferPayload,
      senderState: updatedSender,
      recipientState: updatedRecipient,
    };
  } catch (err: any) {
    return { success: false, error: err.message || "Transfer failed" };
  }
}
