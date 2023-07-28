-- Création du schéma User1
CREATE SCHEMA IF NOT EXISTS User1;

-- Création de la table User1.Establishments
CREATE TABLE User1.Establishments (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255)
);

-- Création de la table User1.Accounts
CREATE TABLE User1.Accounts (
  id SERIAL PRIMARY KEY,
  account_number VARCHAR(255),
  account_name VARCHAR(255),
  establishment_id INT,
  type VARCHAR(255),
  tag VARCHAR(255),
  FOREIGN KEY (establishment_id) REFERENCES User1.Establishments(id)
);

-- Création de la table User1.Transactions
CREATE TABLE User1.Transactions (
  id SERIAL PRIMARY KEY,
  source_account_id INT,
  destination_account_id INT,
  transaction_date TIMESTAMP,
  amount FLOAT,
  description VARCHAR(255),
  category VARCHAR(255),
  FOREIGN KEY (source_account_id) REFERENCES User1.Accounts(id),
  FOREIGN KEY (destination_account_id) REFERENCES User1.Accounts(id)
);

-- Insertion de faux établissements
INSERT INTO User1.Establishments (name) VALUES 
('Etablissement 1'),
('Etablissement 2'),
('Etablissement 3');

-- Insertion de faux comptes
INSERT INTO User1.Accounts (account_number, account_name, establishment_id, type, tag) VALUES 
('123456789', 'Compte Etablissement 1', 1, 'Compte courant', 'Tag 1'),
('987654321', 'Compte Etablissement 2', 2, 'Compte épargne', 'Tag 2'),
('456789123', 'Compte Etablissement 3', 3, 'Compte courant', 'Tag 3');

-- Insertion de fausses transactions avec valeurs aléatoires
INSERT INTO User1.Transactions (source_account_id, destination_account_id , transaction_date, amount, description, category) 
SELECT 
  (SELECT id FROM User1.Accounts ORDER BY RANDOM() LIMIT 1), 
  (SELECT id FROM User1.Accounts WHERE id != (SELECT id FROM User1.Accounts ORDER BY RANDOM() LIMIT 1) ORDER BY RANDOM() LIMIT 1), 
  NOW(), 
  RANDOM() * 1000, -- Pas besoin d'utiliser ROUND ici car la colonne "amount" est de type FLOAT, et PostgreSQL se chargera de la conversion
  'Transaction #1', 
  'Category 1' 
FROM generate_series(1, 100);

INSERT INTO User1.Transactions (source_account_id, destination_account_id , transaction_date, amount, description, category) 
SELECT 
  (SELECT id FROM User1.Accounts WHERE establishment_id = 1 ORDER BY RANDOM() LIMIT 1), 
  (SELECT id FROM User1.Accounts WHERE establishment_id != 1 ORDER BY RANDOM() LIMIT 1), 
  NOW() - INTERVAL '2 years' + (FLOOR(RANDOM() * 730) || ' days')::INTERVAL, 
  RANDOM() * 1000,
  CONCAT('Transaction #', id), 
  CONCAT('Category ', FLOOR(RANDOM() * 10) + 1) 
FROM User1.Transactions 
LIMIT 100;

INSERT INTO User1.Transactions (source_account_id, destination_account_id , transaction_date, amount, description, category) 
SELECT 
  (SELECT id FROM User1.Accounts WHERE establishment_id = 1 ORDER BY RANDOM() LIMIT 1), 
  (SELECT id FROM User1.Accounts WHERE establishment_id = 2 ORDER BY RANDOM() LIMIT 1), 
  NOW() - INTERVAL '2 years' + (FLOOR(RANDOM() * 730) || ' days')::INTERVAL, 
  RANDOM() * 1000,
  CONCAT('Transaction #', id), 
  CONCAT('Category ', FLOOR(RANDOM() * 10) + 1) 
FROM User1.Transactions 
LIMIT 100;

INSERT INTO User1.Transactions (source_account_id, destination_account_id , transaction_date, amount, description, category) 
SELECT 
  (SELECT id FROM User1.Accounts WHERE establishment_id = 2 ORDER BY RANDOM() LIMIT 1), 
  (SELECT id FROM User1.Accounts WHERE establishment_id = 3 ORDER BY RANDOM() LIMIT 1), 
  NOW() - INTERVAL '2 years' + (FLOOR(RANDOM() * 730) || ' days')::INTERVAL, 
  RANDOM() * 1000,
  CONCAT('Transaction #', id), 
  CONCAT('Category ', FLOOR(RANDOM() * 10) + 1) 
FROM User1.Transactions 
LIMIT 100;


CREATE OR REPLACE VIEW User1.AccountBalanceDaily AS
SELECT 
  account_id,
  date,
  balance,
  first_value(balance) OVER (PARTITION BY account_id, date ORDER BY date) AS "Open",
  last_value(balance) OVER (PARTITION BY account_id, date ORDER BY date) AS "Close",
  min(balance) OVER (PARTITION BY account_id, date) AS "Low",
  max(balance) OVER (PARTITION BY account_id, date) AS "High"
FROM (
  SELECT 
    account_id,
    date_trunc('DAY', transaction_date) AS date,
    SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) AS balance
  FROM (
    SELECT 
      destination_account_id AS account_id,
      transaction_date,
      amount
    FROM User1.Transactions
    UNION ALL
    SELECT 
      source_account_id AS account_id,
      transaction_date,
      -amount
    FROM User1.Transactions
  ) AS CombinedTransactions
) AS DailyBalance
ORDER BY 
  account_id, date;