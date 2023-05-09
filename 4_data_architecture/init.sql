-- creation of the database with test data

-- Create table
CREATE TABLE IF NOT EXISTS user_master (
  user_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  phone TEXT NOT NULL,
  payment_details_key TEXT,
  currency VARCHAR(3),
  account_balance DECIMAL(10, 2) DEFAULT 0.00,
  account_blocked BOOLEAN DEFAULT FALSE,
  account_blocked_reason TEXT,
  account_blocked_timestamp TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

TRUNCATE TABLE user_master;

-- Create index
CREATE UNIQUE INDEX IF NOT EXISTS user_master_user_id_idx ON user_master (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS user_master_email_idx ON user_master (email);

-- trigger function

-- Create table
CREATE TABLE IF NOT EXISTS user_account_audit (
  user_id BIGINT NOT NULL,
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  event_type VARCHAR(50) NOT NULL,
  metadata JSONB,
  FOREIGN KEY (user_id) REFERENCES user_master(user_id)
);

TRUNCATE TABLE user_account_audit;

-- Create index
CREATE INDEX IF NOT EXISTS user_account_audit_user_id_idx ON user_account_audit (user_id);
CREATE INDEX IF NOT EXISTS user_account_audit_timestamp_idx ON user_account_audit (timestamp);
CREATE INDEX IF NOT EXISTS user_account_audit_event_type_idx ON user_account_audit (event_type);

-- Insert 10 different users into the user_master table
INSERT INTO user_master (
  name, email, phone, payment_details_key, currency
) VALUES
('User1', 'user1@example.com', '+12345678901', 'payment_key_1', 'USD'),
('User2', 'user2@example.com', '+12345678902', 'payment_key_2', 'USD'),
('User3', 'user3@example.com', '+12345678903', 'payment_key_3', 'USD'),
('User4', 'user4@example.com', '+12345678904', 'payment_key_4', 'USD'),
('User5', 'user5@example.com', '+12345678905', 'payment_key_5', 'USD'),
('User6', 'user6@example.com', '+12345678906', 'payment_key_6', 'USD'),
('User7', 'user7@example.com', '+12345678907', 'payment_key_7', 'USD'),
('User8', 'user8@example.com', '+12345678908', 'payment_key_8', 'USD'),
('User9', 'user9@example.com', '+12345678909', 'payment_key_9', 'USD'),
('User10', 'user10@example.com', '+12345678910', 'payment_key_10', 'USD');
