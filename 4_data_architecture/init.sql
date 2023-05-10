-- creation of the database with test data

-- Table user_account

-- Create table
CREATE TABLE IF NOT EXISTS user_account (
  user_id SERIAL PRIMARY KEY,
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
  created_by INTEGER NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by INTEGER NOT NULL,
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
  audit_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type TEXT NOT NULL,
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
  event_type TEXT;
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
  financial_transaction_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  parking_lot_id INTEGER NOT NULL,
  tracking_event_id INTEGER NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type TEXT NOT NULL,
  metadata jsonb,
  amount numeric NOT NULL,
  currency varchar(3) NOT NULL,
  account_balance numeric NOT NULL,
  created_at timestamp NOT NULL,
  created_by INTEGER NOT NULL
);

-- Create indexes
CREATE INDEX idx_financial_transactions_user_id ON user_account_financial_transactions (user_id);
CREATE INDEX idx_financial_transactions_financial_transaction_id ON user_account_financial_transactions (financial_transaction_id);
CREATE INDEX idx_financial_transactions_event_timestamp ON user_account_financial_transactions (event_timestamp);
CREATE INDEX idx_financial_transactions_event_type ON user_account_financial_transactions (event_type);
CREATE INDEX idx_financial_transactions_parking_lot_id ON user_account_financial_transactions (parking_lot_id);
CREATE INDEX idx_financial_transactions_tracking_event_id ON user_account_financial_transactions (tracking_event_id);

-- parking lot table
CREATE TABLE parking_lot (
  parking_lot_id SERIAL PRIMARY KEY,
  parking_lot_name TEXT NOT NULL,
  address TEXT NOT NULL,
  capacity integer NOT NULL,
  pricing_model_id INTEGER NOT NULL,
  blocked boolean NOT NULL DEFAULT false,
  blocked_reason TEXT,
  blocked_timestamp timestamp,
  full boolean NOT NULL DEFAULT false,
  full_timestamp timestamp,
  created_at timestamp NOT NULL,
  created_by INTEGER NOT NULL,
  updated_at timestamp NOT NULL,
  updated_by INTEGER NOT NULL
);

-- Create indexes
CREATE INDEX idx_parking_lot_parking_lot_id ON parking_lot (parking_lot_id);
CREATE INDEX idx_parking_lot_pricing_model_id ON parking_lot (pricing_model_id);


-- parking lot audit table
CREATE TABLE parking_lot_audit (
  audit_id SERIAL PRIMARY KEY,
  parking_lot_id INTEGER NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type TEXT NOT NULL,
  metadata JSONB,
  capacity integer
);

-- Create indexes
CREATE INDEX idx_parking_lot_audit_parking_lot_id ON parking_lot_audit (parking_lot_id);
CREATE INDEX idx_parking_lot_audit_event_timestamp ON parking_lot_audit (event_timestamp);
CREATE INDEX idx_parking_lot_audit_event_type ON parking_lot_audit (event_type);

-- TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION audit_parking_lot_changes() RETURNS TRIGGER AS $$
DECLARE
  event_type TEXT;
  metadata json;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    event_type := 'parking_lot_created';
  ELSIF (TG_OP = 'UPDATE') THEN
    event_type := 'parking_lot_updated';
  ELSIF (TG_OP = 'DELETE') THEN
    event_type := 'parking_lot_deleted';
  ELSE
    RETURN NULL;
  END IF;

  metadata := row_to_json(NEW);

  INSERT INTO parking_lot_audit (parking_lot_id, event_timestamp, event_type, metadata, capacity)
  VALUES (NEW.parking_lot_id, NOW(), event_type, metadata, NEW.capacity);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_parking_lot_changes
AFTER INSERT OR UPDATE OR DELETE ON parking_lot
FOR EACH ROW EXECUTE FUNCTION audit_parking_lot_changes();

-- Create the parking_lot_events table
CREATE TABLE parking_lot_events (
  tracking_event_id serial PRIMARY KEY,
  parking_lot_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type TEXT NOT NULL,
  metadata json,
  capacity integer
);

-- Create indexes
CREATE INDEX idx_parking_lot_events_parking_lot_id ON parking_lot_events (parking_lot_id);
CREATE INDEX idx_parking_lot_events_user_id ON parking_lot_events (user_id);
CREATE INDEX idx_parking_lot_events_event_timestamp ON parking_lot_events (event_timestamp);
CREATE INDEX idx_parking_lot_events_event_type ON parking_lot_events (event_type);

-- Create the pricing_model table
CREATE TABLE pricing_model (
  pricing_model_id serial PRIMARY KEY,
  name TEXT NOT NULL,
  description text,
  basic_rate_price numeric(10, 2) NOT NULL,
  current_rate_price numeric(10, 2) NOT NULL,
  peak_rate_price numeric(10, 2),
  pricing_model_type TEXT NOT NULL,
  pricing_model_parameters json,
  currency varchar(3) NOT NULL,
  created_at timestamp NOT NULL,
  created_by integer NOT NULL,
  updated_at timestamp,
  updated_by integer
);

-- Create indexes
CREATE INDEX idx_pricing_model_pricing_model_id ON pricing_model (pricing_model_id);

-- Create the pricing_model_audit table
CREATE TABLE pricing_model_audit (
  audit_id serial PRIMARY KEY,
  pricing_model_id integer NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type varchar(255) NOT NULL,
  metadata json,
  price numeric(10, 2)
);

-- Create indexes
CREATE INDEX idx_pricing_model_audit_pricing_model_id ON pricing_model_audit (pricing_model_id);

-- Create the trigger function
CREATE OR REPLACE FUNCTION pricing_model_audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO pricing_model_audit (
    pricing_model_id,
    event_timestamp,
    event_type,
    metadata,
    price
  )
  VALUES (
    NEW.pricing_model_id,
    CURRENT_TIMESTAMP,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'pricing_model_created'
      WHEN TG_OP = 'UPDATE' THEN 'pricing_model_updated'
      WHEN TG_OP = 'DELETE' THEN 'pricing_model_deleted'
      ELSE NULL
    END,
    row_to_json(NEW),
    NEW.current_rate_price
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER pricing_model_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON pricing_model
FOR EACH ROW
EXECUTE FUNCTION pricing_model_audit_trigger_func();


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
