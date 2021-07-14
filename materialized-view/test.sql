INSERT INTO transactions (tx_id, amount, wallet_id, created_at)
SELECT md5((random() * 100000)::text),
    (random() * 10000) + 1,
    (
        SELECT id
        from wallet
        order by random()
        LIMIT 1
    ), NOW() + (random() * (NOW() + '365 days' - NOW()))
from generate_series(1, 10000000);