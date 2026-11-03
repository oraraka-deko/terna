-- =====================================================================
-- TERNA GLOBAL D1 DATABASE SCHEMA
-- Ported from area_game (SQLite dialect for Cloudflare D1)
-- =====================================================================

-- 1. App Users & Profiles
CREATE TABLE IF NOT EXISTS app_users (
  id TEXT PRIMARY KEY,                       -- Telegram user ID (string)
  username TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  custom_name TEXT,
  custom_avatar TEXT,
  bio TEXT,
  is_premium INTEGER NOT NULL DEFAULT 0,
  language_code TEXT NOT NULL DEFAULT 'en',
  country TEXT NOT NULL DEFAULT 'Unknown',
  biometric_enabled INTEGER NOT NULL DEFAULT 0,
  high_value_2fa_enabled INTEGER NOT NULL DEFAULT 0,
  high_value_2fa_threshold REAL NOT NULL DEFAULT 5.0,
  last_seen_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_username ON app_users(username);

-- 2. Gift Shop Catalog
CREATE TABLE IF NOT EXISTS shop_gifts (
  gift_id TEXT PRIMARY KEY,
  collection_id TEXT NOT NULL,
  name TEXT NOT NULL,
  edition_number TEXT NOT NULL,
  price_stars INTEGER NOT NULL,
  price_gram REAL NOT NULL,
  model_count INTEGER NOT NULL DEFAULT 1,
  backdrop_count INTEGER NOT NULL DEFAULT 1,
  symbol_count INTEGER NOT NULL DEFAULT 1,
  is_upgradeable INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_shop_gifts_collection ON shop_gifts(collection_id);

-- 3. User Inventory & Collectible Gifts
CREATE TABLE IF NOT EXISTS user_inventory (
  instance_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  gift_id TEXT NOT NULL,
  name TEXT NOT NULL DEFAULT 'Telegram Gift',
  model_name TEXT NOT NULL DEFAULT 'Standard Edition',
  backdrop_color TEXT,
  edge_color TEXT,
  symbol_name TEXT,
  rarity REAL NOT NULL DEFAULT 0,
  valuation REAL NOT NULL DEFAULT 0,         -- Floor price valuation in TON
  price_stars INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  acquired_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_user_inventory_user ON user_inventory(user_id);

-- 4. Chat Messages (Global, Direct / DM, and Groups)
CREATE TABLE IF NOT EXISTS app_chat_messages (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL DEFAULT 'GLOBAL',      -- 'GLOBAL' | 'DIRECT' | 'GROUP'
  channel_id TEXT NOT NULL DEFAULT 'global', -- 'global' | 'direct' | group_id
  sender_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  sender_avatar TEXT,
  badge TEXT,
  recipient_id TEXT,
  recipient_name TEXT,
  text TEXT NOT NULL,
  reply_to_id TEXT,
  reply_preview TEXT,                        -- JSON string of replied message summary
  reactions TEXT NOT NULL DEFAULT '{}',      -- JSON map of emoji -> [userIds]
  seen_by TEXT NOT NULL DEFAULT '[]',        -- JSON array of userIds
  transfer TEXT,                             -- JSON transfer payload if message contains gift/stars/ton
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_chat_channel ON app_chat_messages(channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_dm ON app_chat_messages(sender_id, recipient_id, created_at DESC);

-- 5. Chat Groups
CREATE TABLE IF NOT EXISTS chat_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '💬',
  creator_id TEXT NOT NULL,
  is_private INTEGER NOT NULL DEFAULT 0,
  members TEXT NOT NULL DEFAULT '[]',        -- JSON array of user IDs
  muted_by TEXT NOT NULL DEFAULT '[]',       -- JSON array of user IDs
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 6. User Friendships
CREATE TABLE IF NOT EXISTS user_friendships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  friend_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING' | 'ACCEPTED' | 'BLOCKED'
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user ON user_friendships(user_id);

-- 7. Double-Entry Ledger Transactions
CREATE TABLE IF NOT EXISTS ledger_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,                        -- 'DEPOSIT_TON' | 'DEPOSIT_STARS' | 'WITHDRAW_TON' | 'WITHDRAW_STARS' | 'TRANSFER_OUT' | 'TRANSFER_IN' | 'GAME_BET' | 'GAME_PAYOUT' | 'GIFT_BUY' | 'GIFT_SELL'
  amount_ton REAL DEFAULT 0,
  amount_stars INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING' | 'CONFIRMED' | 'FAILED'
  comment TEXT,
  tx_hash TEXT,
  boc TEXT,
  details TEXT DEFAULT '{}',                 -- JSON metadata
  created_at INTEGER NOT NULL,
  confirmed_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_ledger_user ON ledger_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_status ON ledger_transactions(status);

-- 8. P2P Pending Transfers (supports high-value 2FA holds)
CREATE TABLE IF NOT EXISTS pending_transfers (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL,
  recipient_id TEXT NOT NULL,
  recipient_name TEXT,
  type TEXT NOT NULL,                        -- 'GIFT' | 'STARS' | 'TON'
  amount REAL NOT NULL DEFAULT 0,
  gift_instance_id TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING' | 'CONFIRMED' | 'REJECTED' | 'EXPIRED'
  telegram_message_id INTEGER,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pending_sender ON pending_transfers(sender_id);
CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_transfers(status);

-- 9. TON Deposits
CREATE TABLE IF NOT EXISTS ton_deposits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  amount_ton REAL NOT NULL,
  comment TEXT NOT NULL,
  user_wallet_address TEXT,
  boc TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING' | 'PENDING_ON_CHAIN' | 'CONFIRMED' | 'FAILED'
  tx_hash TEXT,
  created_at INTEGER NOT NULL,
  confirmed_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_ton_deposits_user ON ton_deposits(user_id);

-- 10. Telegram Stars Invoices
CREATE TABLE IF NOT EXISTS stars_invoices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  stars_amount INTEGER NOT NULL,
  invoice_link TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING',    -- 'PENDING' | 'CONFIRMED' | 'EXPIRED'
  created_at INTEGER NOT NULL,
  confirmed_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_stars_invoices_user ON stars_invoices(user_id);

-- 11. Withdrawals
CREATE TABLE IF NOT EXISTS withdrawals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  currency TEXT NOT NULL,                    -- 'TON' | 'STARS'
  amount REAL NOT NULL,
  destination TEXT NOT NULL,                 -- TON Address or Telegram ID
  status TEXT NOT NULL DEFAULT 'PENDING_HOLD', -- 'PENDING_HOLD' | 'PROCESSED' | 'REJECTED'
  tx_hash TEXT,
  admin_notes TEXT,
  created_at INTEGER NOT NULL,
  processed_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_withdrawals_user ON withdrawals(user_id);

-- 12. Provably Fair Game Rounds
CREATE TABLE IF NOT EXISTS game_rounds (
  id TEXT PRIMARY KEY,
  game_id TEXT NOT NULL,                     -- 'plinko' | 'tower' | 'upgrade' | 'higher_lower' | 'mines' | 'roulette' | 'territory'
  user_id TEXT NOT NULL,
  currency TEXT NOT NULL,
  bet_amount REAL NOT NULL,
  payout_amount REAL NOT NULL DEFAULT 0,
  multiplier REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'COMPLETED',  -- 'COMPLETED' | 'BUSTED' | 'PUSH'
  server_seed TEXT,
  server_seed_hash TEXT,
  client_seed TEXT,
  nonce INTEGER,
  game_details TEXT DEFAULT '{}',            -- JSON details (path, tiles, cards, etc.)
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_game_rounds_user ON game_rounds(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_rounds_game ON game_rounds(game_id);

-- 13. Audit Queue Logs (High throughput batch insertion)
CREATE TABLE IF NOT EXISTS game_audit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  game_type TEXT NOT NULL,
  currency TEXT NOT NULL,
  bet_amount REAL NOT NULL,
  payout_amount REAL NOT NULL,
  server_seed TEXT NOT NULL,
  client_seed TEXT NOT NULL,
  nonce INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

-- 14. System Configuration (Database-backed Treasury Wallet & Settings)
CREATE TABLE IF NOT EXISTS system_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

INSERT OR IGNORE INTO system_config (key, value, updated_at) VALUES 
  ('treasury_wallet_address', 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA_xxx', 1700000000000),
  ('deposit_multiplier_ton', '100', 1700000000000),
  ('min_deposit_ton', '0.1', 1700000000000),
  ('min_deposit_stars', '10', 1700000000000);

