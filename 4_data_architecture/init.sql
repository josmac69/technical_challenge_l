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
  updated_at TIMESTAMP,
  updated_by INTEGER,
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
  pricing_model_id INTEGER NOT NULL,
  tracking_event_id INTEGER NOT NULL,
  event_timestamp timestamp NOT NULL,
  event_type TEXT NOT NULL,
  metadata jsonb,
  amount numeric NOT NULL,
  currency varchar(3) NOT NULL,
  account_balance numeric NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER NOT NULL
);

-- Create indexes
CREATE INDEX idx_financial_transactions_user_id ON user_account_financial_transactions (user_id);
CREATE INDEX idx_financial_transactions_financial_transaction_id ON user_account_financial_transactions (financial_transaction_id);
CREATE INDEX idx_financial_transactions_event_timestamp ON user_account_financial_transactions (event_timestamp);
CREATE INDEX idx_financial_transactions_event_type ON user_account_financial_transactions (event_type);
CREATE INDEX idx_financial_transactions_parking_lot_id ON user_account_financial_transactions (parking_lot_id);
CREATE INDEX idx_financial_transactions_tracking_event_id ON user_account_financial_transactions (tracking_event_id);

-- trigger function for financial transaction
CREATE OR REPLACE FUNCTION update_account_balance() RETURNS TRIGGER AS $$
BEGIN
  CASE
  WHEN NEW.event_type = 'account_charged' THEN
    UPDATE user_account
    SET account_balance = account_balance - NEW.amount
    WHERE user_id = NEW.user_id;

    NEW.account_balance = (SELECT account_balance FROM user_account WHERE user_id = NEW.user_id);

  WHEN NEW.event_type = 'account_increased' THEN
    UPDATE user_account
    SET account_balance = account_balance + NEW.amount
    WHERE user_id = NEW.user_id;

    NEW.account_balance = (SELECT account_balance FROM user_account WHERE user_id = NEW.user_id);
  ELSE
    RETURN NEW;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_account_balance_trigger
AFTER INSERT ON user_account_financial_transactions
FOR EACH ROW
EXECUTE FUNCTION update_account_balance();

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
  parking_lot_full boolean NOT NULL DEFAULT false,
  full_timestamp timestamp,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER NOT NULL,
  updated_at timestamp,
  updated_by INTEGER
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
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
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

-- Create the user_parking_lot_price table
CREATE TABLE user_parking_lot_price (
  price_id serial PRIMARY KEY,
  user_id integer NOT NULL,
  parking_lot_id integer NOT NULL,
  pricing_model_id integer NOT NULL,
  tracking_event_id integer NOT NULL,
  price numeric(10, 2) NOT NULL,
  currency varchar(3) NOT NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by integer NOT NULL,
  updated_at timestamp,
  updated_by integer
);

-- Create indexes
CREATE INDEX idx_user_parking_lot_price_user_id ON user_parking_lot_price (user_id);
CREATE INDEX idx_user_parking_lot_price_parking_lot_id ON user_parking_lot_price (parking_lot_id);

-- Create the user_parking_lot_price_audit table
-- Create the user_parking_lot_price_audit table
CREATE TABLE user_parking_lot_price_audit (
  audit_id serial PRIMARY KEY,
  event_timestamp timestamp NOT NULL,
  event_type varchar(64) NOT NULL,
  price_id integer NOT NULL,
  user_id integer NOT NULL,
  parking_lot_id integer NOT NULL,
  pricing_model_id integer NOT NULL,
  tracking_event_id integer NOT NULL,
  price numeric(10, 2) NOT NULL,
  currency varchar(3) NOT NULL,
  metadata json
);

-- Create indexes
CREATE INDEX idx_user_parking_lot_price_audit_user_id ON user_parking_lot_price_audit (user_id);
CREATE INDEX idx_user_parking_lot_price_audit_parking_lot_id ON user_parking_lot_price_audit (parking_lot_id);

-- Create the trigger function for user_parking_lot_price
CREATE OR REPLACE FUNCTION audit_user_parking_lot_price()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO user_parking_lot_price_audit (event_timestamp, event_type, price_id, user_id, parking_lot_id, pricing_model_id, tracking_event_id, price, currency, metadata)
    VALUES (NOW(), 'entry', NEW.price_id, NEW.user_id, NEW.parking_lot_id, NEW.pricing_model_id, NEW.tracking_event_id, NEW.price, NEW.currency, NULL);
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO user_parking_lot_price_audit (event_timestamp, event_type, price_id, user_id, parking_lot_id, pricing_model_id, tracking_event_id, price, currency, metadata)
    VALUES (NOW(), 'price_changed', NEW.price_id, NEW.user_id, NEW.parking_lot_id, NEW.pricing_model_id, NEW.tracking_event_id, NEW.price, NEW.currency, NULL);
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO user_parking_lot_price_audit (event_timestamp, event_type, price_id, user_id, parking_lot_id, pricing_model_id, tracking_event_id, price, currency, metadata)
    VALUES (NOW(), 'exit', OLD.price_id, OLD.user_id, OLD.parking_lot_id, OLD.pricing_model_id, OLD.tracking_event_id, OLD.price, OLD.currency, NULL);
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger for user_parking_lot_price
CREATE TRIGGER trg_audit_user_parking_lot_price
AFTER INSERT OR UPDATE OR DELETE ON user_parking_lot_price
FOR EACH ROW
EXECUTE FUNCTION audit_user_parking_lot_price();


-- Insert 10 different users into the user_account table
INSERT INTO user_account (
  user_name, email, phone, payment_details_key, currency, created_at, created_by
) VALUES
('User1', 'user1@example.com', '+12345678901', 'payment_key_1', 'USD', '2023-05-01', 0),
('User2', 'user2@example.com', '+12345678902', 'payment_key_2', 'USD', '2023-05-01', 0),
('User3', 'user3@example.com', '+12345678903', 'payment_key_3', 'USD', '2023-05-01', 0),
('User4', 'user4@example.com', '+12345678904', 'payment_key_4', 'USD', '2023-05-01', 0),
('User5', 'user5@example.com', '+12345678905', 'payment_key_5', 'USD', '2023-05-01', 0),
('User6', 'user6@example.com', '+12345678906', 'payment_key_6', 'USD', '2023-05-01', 0),
('User7', 'user7@example.com', '+12345678907', 'payment_key_7', 'USD', '2023-05-01', 0),
('User8', 'user8@example.com', '+12345678908', 'payment_key_8', 'USD', '2023-05-01', 0),
('User9', 'user9@example.com', '+12345678909', 'payment_key_9', 'USD', '2023-05-01', 0),
('User10', 'user10@example.com', '+12345678910', 'payment_key_10', 'USD', '2023-05-01', 0);

-- pricing model records
INSERT INTO pricing_model
(name, description, basic_rate_price, current_rate_price, peak_rate_price, pricing_model_type, pricing_model_parameters, currency, created_by)
VALUES
('Static - Standard Hourly', 'Basic hourly rate for parking', 2.50, 2.50, NULL, 'static',
'{"hours": [{"hour": 0, "price": 2.00}, {"hour": 1, "price": 2.00}, {"hour": 2, "price": 2.00},
{"hour": 3, "price": 2.00}, {"hour": 4, "price": 2.00}, {"hour": 5, "price": 2.00},
{"hour": 6, "price": 2.00}, {"hour": 7, "price": 2.50}, {"hour": 8, "price": 3.00},
{"hour": 9, "price": 3.50}, {"hour": 10, "price": 3.50}, {"hour": 11, "price": 3.50},
{"hour": 12, "price": 3.50}, {"hour": 13, "price": 3.50}, {"hour": 14, "price": 3.50},
{"hour": 15, "price": 3.50}, {"hour": 16, "price": 3.50}, {"hour": 17, "price": 4.00},
{"hour": 18, "price": 4.00}, {"hour": 19, "price": 4.00}, {"hour": 20, "price": 3.50},
{"hour": 21, "price": 3.00}, {"hour": 22, "price": 2.50}, {"hour": 23, "price": 2.00}]}'::json, 'USD', 0);

INSERT INTO pricing_model
(name, description, basic_rate_price, current_rate_price, peak_rate_price, pricing_model_type, pricing_model_parameters, currency, created_by)
VALUES
('Static - Early Bird', 'Discounted rate for parking before 9am', 5.00, 5.00, 7.50, 'static',
'{"hours": [{"hour": 0, "price": 5.00}, {"hour": 1, "price": 5.00}, {"hour": 2, "price": 5.00},
{"hour": 3, "price": 5.00}, {"hour": 4, "price": 5.00}, {"hour": 5, "price": 5.00},
{"hour": 6, "price": 5.00}, {"hour": 7, "price": 5.00}, {"hour": 8, "price": 5.00},
{"hour": 9, "price": 5.00}, {"hour": 10, "price": 7.50}, {"hour": 11, "price": 7.50},
{"hour": 12, "price": 7.50}, {"hour": 13, "price": 7.50}, {"hour": 14, "price": 7.50},
{"hour": 15, "price": 7.50}, {"hour": 16, "price": 7.50}, {"hour": 17, "price": 7.50},
{"hour": 18, "price": 7.50}, {"hour": 19, "price": 7.50}, {"hour": 20, "price": 7.50},
{"hour": 21, "price": 7.50}, {"hour": 22, "price": 7.50}, {"hour": 23, "price": 7.50}]}'::json, 'USD', 0);

INSERT INTO pricing_model
(name, description, basic_rate_price, current_rate_price, peak_rate_price, pricing_model_type, pricing_model_parameters, currency, created_by)
VALUES
('Dynamic Price 80%', 'Price increases as lot capacity reaches 80%', 3.00, 3.00, 6.00, 'dynamic', '{"periodicity": 60,
"rates": [{"threshold_percent": 80, "formula": "basic_rate_price + (current_rate_price - basic_rate_price) * (0.8 - capacity) / (capacity)"}] }'::json,
'USD', 0);

INSERT INTO pricing_model
(name, description, basic_rate_price, current_rate_price, peak_rate_price, pricing_model_type, pricing_model_parameters, currency, created_by)
VALUES
('Dynamic Price 90%', 'Price increases as lot capacity reaches 90%', 2.50, 2.50, 5.00, 'dynamic', '{"periodicity": 30,
"rates": [{"threshold_percent": 90, "formula": "basic_rate_price + (current_rate_price - basic_rate_price) * (0.9 - capacity) / (capacity)"}] }'::json,
'USD', 0);

INSERT INTO pricing_model
(name, description, basic_rate_price, current_rate_price, peak_rate_price, pricing_model_type, pricing_model_parameters, currency, created_by)
VALUES
('Dynamic Price 50%, 80%', 'Price increases as lot capacity reaches 50% and 80%', 7.50, 7.50, 15.00, 'dynamic', '{"periodicity": 30,
"rates": [{"threshold_percent": 50, "formula": "basic_rate_price + (current_rate_price - basic_rate_price) * (0.9 - capacity) / (capacity) + 1.00"},
{"threshold_percent": 80, "formula": "basic_rate_price + (current_rate_price - basic_rate_price) * (0.9 - capacity) / (capacity) + 5.00"}] }'::json,
'USD', 0);

-- parking lot records
INSERT INTO parking_lot (parking_lot_name, address, capacity, pricing_model_id, blocked, parking_lot_full, created_by)
VALUES ('Central Parking Garage', '123 Main St', 100, 1, false, false, 0);
INSERT INTO parking_lot (parking_lot_name, address, capacity, pricing_model_id, blocked, parking_lot_full, created_by)
VALUES ('North Parking Lot', '789 Elm St', 60, 2, false, false, 0);
INSERT INTO parking_lot (parking_lot_name, address, capacity, pricing_model_id, blocked, parking_lot_full, created_by)
VALUES ('South Parking Deck', '456 Oak St', 140, 3, false, false, 0);
INSERT INTO parking_lot (parking_lot_name, address, capacity, pricing_model_id, blocked, parking_lot_full, created_by)
VALUES ('East Parking Lot', '555 Maple Ave', 80, 4, false, false, 0);
INSERT INTO parking_lot (parking_lot_name, address, capacity, pricing_model_id, blocked, parking_lot_full, created_by)
VALUES ('West Parking Garage', '777 Walnut St', 50, 5, false, false, 0);

INSERT INTO user_account_financial_transactions (
    user_id,
    parking_lot_id,
    pricing_model_id,
    tracking_event_id,
    event_timestamp,
    event_type,
    metadata,
    amount,
    currency,
    account_balance,
    created_at,
    created_by
)
VALUES
    (1, 1, 1, 11, '2023-05-01 10:30:00', 'account_increased', '{}', 50, 'USD', 50, '2023-05-01', 1),
    (2, 1, 1, 11, '2023-05-01 11:15:00', 'account_increased', '{}', 60, 'USD', 60, '2023-05-01', 1),
    (3, 1, 1, 11, '2023-05-01 12:20:00', 'account_increased', '{}', 80, 'USD', 80, '2023-05-01', 1),
    (4, 1, 1, 11, '2023-05-01 13:05:00', 'account_increased', '{}', 70, 'USD', 70, '2023-05-01', 1),
    (5, 1, 1, 11, '2023-05-01 14:30:00', 'account_increased', '{}', 150, 'USD', 150, '2023-05-01', 1),
    (6, 1, 1, 11, '2023-05-01 15:10:00', 'account_increased', '{}', 60, 'USD', 60, '2023-05-01', 1),
    (7, 1, 1, 11, '2023-05-01 16:45:00', 'account_increased', '{}', 120, 'USD', 120, '2023-05-01', 1),
    (8, 1, 1, 11, '2023-05-01 17:20:00', 'account_increased', '{}', 80, 'USD', 80, '2023-05-01', 1),
    (9, 1, 1, 11, '2023-05-01 18:00:00', 'account_increased', '{}', 90, 'USD', 90, '2023-05-01', 1),
    (10, 1, 1, 11, '2023-05-01 11:50:00', 'account_increased', '{}', 80, 'USD', 80, '2023-05-01', 1);

INSERT INTO user_account_financial_transactions (
  user_id,
  parking_lot_id,
  pricing_model_id,
  tracking_event_id,
  event_timestamp,
  event_type,
  metadata,
  amount,
  currency,
  account_balance,
  created_by
) VALUES
  (1, 1, 1, 11, '2023-05-10 08:31:00', 'usage_charged', '{}', 3.00, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 09:31:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 10:31:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 11:31:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 12:31:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 13:31:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (1, 1, 1, 11, '2023-05-10 14:15:00', 'account_charged', '{}', 20.50, 'USD', 0, 1);

INSERT INTO user_account_financial_transactions (
  user_id,
  parking_lot_id,
  pricing_model_id,
  tracking_event_id,
  event_timestamp,
  event_type,
  metadata,
  amount,
  currency,
  account_balance,
  created_by
) VALUES
  (2, 1, 1, 11, '2023-05-10 12:45:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 13:45:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 14:45:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 15:45:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 16:45:00', 'usage_charged', '{}', 3.50, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 17:45:00', 'usage_charged', '{}', 4.00, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 18:45:00', 'usage_charged', '{}', 4.00, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 19:45:00', 'usage_charged', '{}', 4.00, 'USD', 0, 0),
  (2, 1, 1, 11, '2023-05-10 20:11:00', 'account_charged', '{}', 29.50, 'USD', 0, 1);
