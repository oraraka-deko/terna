const encoder = new TextEncoder();

// Precomputed hex lookup table for zero-allocation byte-to-hex conversion
const byteToHexTable: string[] = [];
for (let n = 0; n <= 0xff; ++n) {
  byteToHexTable.push(n.toString(16).padStart(2, "0"));
}

export function bytesToHex(bytes: Uint8Array): string {
  let hex = "";
  for (let i = 0; i < bytes.length; i++) {
    hex += byteToHexTable[bytes[i]];
  }
  return hex;
}

export async function sha256Hex(input: string): Promise<string> {
  const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(input));
  return bytesToHex(new Uint8Array(hashBuffer));
}

export async function hmacSha256Bytes(keyStr: string | ArrayBuffer, message: string): Promise<Uint8Array> {
  const keyData = typeof keyStr === "string" ? encoder.encode(keyStr) : keyStr;
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(message));
  return new Uint8Array(sig);
}

/**
 * Deterministically converts (serverSeed, clientSeed, nonce) into 32 random bytes
 * and a float percentile [0.0000 - 100.0000]
 */
export async function computeProvablyFairRoll(
  serverSeed: string,
  clientSeed: string,
  nonce: number
): Promise<{ bytes: Uint8Array; rollPercentile: number; hashHex: string }> {
  const bytes = await hmacSha256Bytes(serverSeed, `${clientSeed}:${nonce}`);
  const hashHex = bytesToHex(bytes);

  // Read first 4 bytes as unsigned 32-bit integer
  const view = new DataView(bytes.buffer);
  const uint32 = view.getUint32(0, false);
  const rollPercentile = (uint32 / 0xffffffff) * 100.0;

  return { bytes, rollPercentile, hashHex };
}

/**
 * Verifies Telegram Mini App initData per official Telegram specification
 */
export async function verifyTelegramInitData(
  initDataRaw: string,
  botToken: string
): Promise<{ id: string; username: string; photoUrl: string }> {
  const params = new URLSearchParams(initDataRaw);
  const receivedHash = params.get("hash");
  if (!receivedHash) throw new Error("Missing Telegram hash");

  params.delete("hash");
  const sortedKeys = Array.from(params.keys()).sort();
  const dataCheckString = sortedKeys.map((k) => `${k}=${params.get(k)}`).join("\n");

  const secretKey = await hmacSha256Bytes("WebAppData", botToken);
  const calculatedBytes = await hmacSha256Bytes(secretKey.buffer as ArrayBuffer, dataCheckString);
  const calculatedHex = bytesToHex(calculatedBytes);

  if (calculatedHex !== receivedHash) {
    throw new Error("Invalid Telegram initData signature");
  }

  const userJson = params.get("user");
  if (!userJson) throw new Error("Missing user object in initData");
  const user = JSON.parse(userJson);

  return {
    id: String(user.id),
    username: user.username ? `@${user.username}` : user.first_name || `User_${user.id}`,
    photoUrl: user.photo_url || "",
  };
}

export function generateRandomSeedHex(byteLength = 32): string {
  const arr = new Uint8Array(byteLength);
  crypto.getRandomValues(arr);
  return bytesToHex(arr);
}
