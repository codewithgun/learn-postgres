CREATE TABLE users (
    id SERIAL NOT NULL,
    name TEXT,
    active BOOLEAN DEFAULT true,
    PRIMARY KEY (id)
);
CREATE TABLE coins (id SERIAL NOT NULL, name TEXT, PRIMARY KEY (id));
CREATE TABLE addresses (
    id SERIAL NOT NULL,
    address TEXT NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);
CREATE TABLE wallet (
    id SERIAL NOT NULL,
    balance DECIMAL(15, 2) NOT NULL,
    address_id INTEGER NOT NULL,
    coin_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (address_id) REFERENCES addresses (id),
    FOREIGN KEY (coin_id) REFERENCES coins(id)
);
CREATE TABLE transactions (
    id SERIAL NOT NULL,
    tx_id TEXT NOT NULL UNIQUE,
    amount DECIMAL(50, 30) NOT NULL,
    wallet_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (wallet_id) REFERENCES wallet(id)
);