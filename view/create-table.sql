CREATE TABLE users (
    id SERIAL NOT NULL,
    name TEXT,
    active BOOLEAN DEFAULT true
);
CREATE TABLE coins (id SERIAL NOT NULL, name TEXT);
CREATE TABLE addresses (
    id SERIAL NOT NULL,
    address NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id)
);
CREATE TABLE wallet (
    id SERIAL NOT NULL,
    balance DECIMAL(15, 2) NOT NULL,
    address_id INTEGER NOT NULL,
    coin_id INTEGER NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses (id),
    FOREIGN KEY (coin_id) REFERENCES coins(id)
);