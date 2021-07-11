CREATE VIEW random_date AS
select NOW() + (random() * (NOW() + '60 days' - NOW())) as r_date;