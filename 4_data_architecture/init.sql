-- creation of the database with test data

-- Table user_account

-- Create table
CREATE TABLE IF NOT EXISTS user_account (
  user_id BIGSERIAL PRIMARY KEY,
  user_name TEXT NOT NULL,
  email TEXT NOT NULL,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  phone TEXT NOT NULL,
  payment_details_key TEXT,
  currency VARCHAR(3) NOT NULL,
  account_balance DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  account_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  account_blocked_reason TEXT,
  account_blocked_timestamp TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata jsonb
);

-- Truncate table - for initial testing clean start
TRUNCATE TABLE user_account;

-- Create index
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_account_user_id ON user_account (user_id);
CREATE INDEX IF NOT EXISTS idx_user_account_user_name ON user_account (user_name);
CREATE INDEX IF NOT EXISTS idx_user_account_email ON user_account (email);
CREATE INDEX IF NOT EXISTS idx_user_account_phone ON user_account (phone);

-- trigger function

-- Table user_account_audit

-- Create table
CREATE TABLE user_account_audit (
  audit_id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type varchar(255) NOT NULL,
  metadata json
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_account_audit_user_id ON user_account_audit (user_id);
CREATE INDEX IF NOT EXISTS idx_user_account_audit_event_timestamp ON user_account_audit (event_timestamp);
CREATE INDEX IF NOT EXISTS idx_user_account_audit_event_type ON user_account_audit (event_type);

-- trigger function
-- Trigger function
CREATE OR REPLACE FUNCTION user_account_audit_trigger() RETURNS TRIGGER AS $$
DECLARE
  event_type varchar(255);
  old_data json;
  new_data json;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    event_type := 'account_created';
    new_data := to_json(NEW);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.email_verified IS DISTINCT FROM NEW.email_verified) THEN
      event_type := 'email_verified';
    ELSE
      event_type := 'account_updated';
    END IF;
    old_data := to_json(OLD);
    new_data := to_json(NEW);
  ELSIF (TG_OP = 'DELETE') THEN
    event_type := 'account_deleted';
    old_data := to_json(OLD);
    new_data := NULL;
  END IF;

  INSERT INTO user_account_audit (user_id, event_timestamp, event_type, metadata)
  VALUES (COALESCE(NEW.user_id, OLD.user_id), NOW(), event_type,
          json_build_object('old_data', old_data, 'new_data', new_data));

  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER user_account_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON user_account
FOR EACH ROW EXECUTE FUNCTION user_account_audit_trigger();


-- Financial transaction table
CREATE TABLE user_account_financial_transactions (
  financial_transaction_id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  parking_lot_id bigint NOT NULL,
  tracking_event_id bigint NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type varchar(255) NOT NULL,
  metadata jsonb,
  amount numeric NOT NULL,
  currency varchar(3) NOT NULL,
  account_balance numeric NOT NULL,
  created_at timestamp NOT NULL,
  created_by varchar(255) NOT NULL
);

-- Create indexes
CREATE INDEX idx_financial_transactions_user_id ON user_account_financial_transactions (user_id);
CREATE INDEX idx_financial_transactions_financial_transaction_id ON user_account_financial_transactions (financial_transaction_id);
CREATE INDEX idx_financial_transactions_event_timestamp ON user_account_financial_transactions (event_timestamp);
CREATE INDEX idx_financial_transactions_event_type ON user_account_financial_transactions (event_type);
CREATE INDEX idx_financial_transactions_parking_lot_id ON user_account_financial_transactions (parking_lot_id);
CREATE INDEX idx_financial_transactions_tracking_event_id ON user_account_financial_transactions (tracking_event_id);



-- Insert 10 different users into the user_account table
INSERT INTO user_account (
  user_name, email, phone, payment_details_key, currency
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
