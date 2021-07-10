CREATE VIEW wallet_detail as
SELECT a.address as address,
    w.id as wallet_id,
    w.balance as balance,
    u.name as name,
    c.name as coin
from wallet w
    LEFT JOIN addresses a on a.id = w.address_id
    LEFT JOIN users u on a.user_id = u.id
    LEFT JOIN coins c on c.id = w.coin_id
where u.active = true;