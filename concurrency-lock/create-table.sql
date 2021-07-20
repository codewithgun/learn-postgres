CREATE TABLE wallets (
    id SERIAL NOT NULL,
    balance DECIMAL(30, 20) NOT NULL,
    name TEXT NOT NULL UNIQUE,
    PRIMARY KEY (id)
)