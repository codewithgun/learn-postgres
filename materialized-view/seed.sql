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