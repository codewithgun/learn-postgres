# Overview
View, is a logical table in database. It doesn't store `data` or `result` on the disk. Only the definition of the view was stored. The query in the view is run every time when the view is being used in query. Therefore, creating view doesn't yield any performance gain. In Postgres, the view is `read-only`, any insert, update or delete operation is not allowed to be perform on the view. It is similar to CTE (Common Table Expression). The only difference between them is the view can be referenced by any query/transaction, while CTE only available for that query session.

## Types of view
- Normal view
- Materialized view
- Recursive view

## Advantages
- Simplify complex query
- Show only authorized data to the user based on permission

# Experiment
Firstly, let's create tables and populate some data by running `create-table.sql` and `seed.sql`. The database design is a basic cryptocurrency wallet system, where user can have wallet for different token or native token.

Let's say, we could like to show `address`, `user_name`, `coin_name`, `balance` for each `wallet` where the wallet user is `active`, the query will be
```
SELECT a.address as address, w.balance as balance, u.name as name, c.name as coin from wallet w LEFT JOIN addresses a on a.id = w.address_id LEFT JOIN users u on a.user_id = u.id LEFT JOIN coins c on c.id = w.coin_id where u.active = true;
```
We can simplify the query above by creating a view.
```
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
```
After that, instead of executing the complex query, we can query from the view.
```
SELECT * FROM wallet_detail;
```
Yet, it yield the same result. Besides that, we can further join the view with other table like the following;
```
SELECTs * from transactions t left join wallet_detail w on w.id = t.wallet_id;
```
### Performance
---
Let's compare the execution plan of  `view` and `join query`.
Before that, let's update the postgres `statistic` for planning the execution plan by running the following sql.
```
ANALYZE
```
Then, execute the query below to the result of execution plan.
```
EXPLAIN SELECT a.address as address, w.balance as balance, u.name as name, c.name as coin from wallet w LEFT JOIN addresses a on a.id = w.address_id LEFT JOIN users u on a.user_id = u.id LEFT JOIN coins c on c.id = w.coin_id where u.active = true;
```
It produced the following execution plan
```
Nested Loop Left Join  (cost=1.09..4.30 rows=2 width=61)
   Join Filter: (c.id = w.coin_id)
   ->  Nested Loop  (cost=1.09..3.22 rows=2 width=58)
         Join Filter: (a.user_id = u.id)
         ->  Seq Scan on users u  (cost=0.00..1.02 rows=1 width=16)
               Filter: active
         ->  Hash Join  (cost=1.09..2.15 rows=4 width=50)
               Hash Cond: (w.address_id = a.id)
               ->  Seq Scan on wallet w  (cost=0.00..1.04 rows=4 width=11)
               ->  Hash  (cost=1.04..1.04 rows=4 width=47)
                     ->  Seq Scan on addresses a  (cost=0.00..1.04 rows=4 width=47)
   ->  Materialize  (cost=0.00..1.03 rows=2 width=11)
         ->  Seq Scan on coins c  (cost=0.00..1.02 rows=2 width=11)
```
Now, let's check out the execution plan when `query` from the view.
```
EXPLAIN SELECT * from wallet_detail;
```
And, it produced the exact same execution plan as we running the query directly.
```
Nested Loop Left Join  (cost=1.09..4.30 rows=2 width=65)
   Join Filter: (c.id = w.coin_id)
   ->  Nested Loop  (cost=1.09..3.22 rows=2 width=62)
         Join Filter: (a.user_id = u.id)
         ->  Seq Scan on users u  (cost=0.00..1.02 rows=1 width=16)
               Filter: active
         ->  Hash Join  (cost=1.09..2.15 rows=4 width=54)
               Hash Cond: (w.address_id = a.id)
               ->  Seq Scan on wallet w  (cost=0.00..1.04 rows=4 width=15)
               ->  Hash  (cost=1.04..1.04 rows=4 width=47)
                     ->  Seq Scan on addresses a  (cost=0.00..1.04 rows=4 width=47)
   ->  Materialize  (cost=0.00..1.03 rows=2 width=11)
         ->  Seq Scan on coins c  (cost=0.00..1.02 rows=2 width=11)
```
Therefore, we can conclude that using view doesn't yield any performance gain. What it does is get the definition of the `view`, and execute the underlying query.

### View within view
---
We would like to show the total transaction count of all coins where the user is active. We can create a view for it, where the view will query from another view.
```
CREATE VIEW active_transaction_summary AS select count(tx.id) as total, wd.coin from  wallet_detail wd left join transactions tx on wd.wallet_id = tx.wallet_id group by (wd.coin);
```
You will notice that, the view above is querying from `wallet_detail` view and `join` with `transactions` table. It is a view, consits of another view. Then, you can run `SELECT * FROM active_transaction_summary` to get the result instead of running complex query.

### Security (authorization)
---
We can expose only certain columns of the table to other database user (`role`) by granting privileges of the view to that user, and deny the access to all the base table. 

**Scenario**

We are corporating with another company called `alice`, which is a big data company. We are required to give them all of our transaction records for data analysis But, we do not wish to expose all the sensitive details of the transaction.

First, we create a `user` for `alice` company.
```
CREATE ROLE alice WITH LOGIN PASSWORD 'abcd1234';
```
Check whether the `alice` user was created by using the query below.
```
SELECT rolname FROM pg_roles WHERE rolname = 'alice';
```
After that, we create a view, which will select only the necessary information needed by `alice`.
```
CREATE VIEW transaction_analysis AS select tx.tx_id "hash", tx.amount "amount", a.address "address", c.name "coin" from transactions tx left join wallet w on tx.wallet_id = w.id left join coins c on c.id = w.coin_id left join addresses a on a.id = w.address_id;
```
We grant the access to `public` schema, then we grant read-only privilege to `alice`. However, since view is read-only, we can grant full privilege to `alice` as well.
```
GRANT ALL PRIVILEGES ON SCHEMA public TO alice;
GRANT SELECT ON transaction_analysis TO alice;
```
Now, let's test whether the authorization is working by login as `alice`.
```
psql -U alice -d postgres
```
Then, we try to query from an unauthorized table.
```
SELECT * from addresses;
```
Postgres returned us `ERROR:  permission denied for table addresses`. Let's query from the view `transaction_analysis` which alice is authorized to access.
```
SELECT * FROM transaction_analysis;
```
Postgres returned the result of the view.
| hash | amount | address | coin |
| --- | --- | --- | --- |
| c598a424669bcde2c03d37b24714b5b63c3604b8b0f4849eed9bbf841aa4a49 | 10.00 | TAUN6FwrnwwmaEqYcckffC7wYmbaS6cBiX | Tron |
| ... | ... | ... | ... |