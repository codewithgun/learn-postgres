INSERT INTO users (name, active)
VALUES ('codewithgun', true);
INSERT INTO users (name, active)
VALUES ('codewithlove', true);
INSERT INTO coins (name)
VALUES ('Ethereum');
INSERT INTO coins (name)
VALUES ('Tron');
INSERT INTO addresses (address, user_id)
VALUES ('TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX', 1);
INSERT INTO addresses (address, user_id)
VALUES ('TN3W4H6rK2ce4vX9YnFQHwKENnHjoxb3m9', 2);
INSERT INTO addresses (address, user_id)
VALUES ('0x723CD86Dc2295D31Fd5042367dD52093E799B168', 1);
INSERT INTO addresses (address, user_id)
VALUES ('0x2886D2A190f00aA324Ac5BF5a5b90217121D5756', 2);
INSERT INTO wallet (balance, address_id, coin_id)
VALUES (0, 1, 2);
INSERT INTO wallet (balance, address_id, coin_id)
VALUES (0, 2, 2);
INSERT INTO wallet (balance, address_id, coin_id)
VALUES (0, 3, 1);
INSERT INTO wallet (balance, address_id, coin_id)
VALUES (0, 4, 1);
INSERT INTO transactions (tx_id, amount, wallet_id)
VALUES (
        'c598a424669bcde2c03d37b24714b5b63c3604b8b0f4849eed9bbf841aa4a490',
        10,
        1
    );
INSERT INTO transactions (tx_id, amount, wallet_id)
VALUES (
        '9dc3cfa55124a37a2a29c35b5cc7a3bf913832fff182748cad28f4089bd88878',
        10,
        2
    );
INSERT INTO transactions (tx_id, amount, wallet_id)
VALUES (
        '0x121443a88291b0a4982b35ee0720b677249c928b23cd1560e5b7fe3e0098d824',
        1,
        3
    );
INSERT INTO transactions (tx_id, amount, wallet_id)
VALUES (
        '0x2155098b4c747acf512d28debefb51c46c8395391e18588447454947cf8a359e',
        1,
        4
    );