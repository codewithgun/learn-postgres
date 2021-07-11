CREATE VIEW random_name AS
SELECT MD5(random()::text) as a;
CREATE VIEW random_date AS
select NOW() + (random() * (NOW() + '365 days' - NOW())) as b;
CREATE VIEW random_age AS
SELECT floor(random() * 50) + 1 as c;