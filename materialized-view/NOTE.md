# Overview
Materialized view is similar to view. We may think it as an `extended` view, where it store the view definition such as `query` underlying, at the same time it store the result as well. Since it `extended` view, therefore, materialized view is `read-only`. The `result` stored in materialized view is not up to date until it is `refreshed`. The materialized view can be further optimized by `indexing`.

It is best to use in situation, where the `query` was heavy and the completeness of the data was not crucial. For example, daily summary, monthly summary.

## Advantages
- Hide the complexity of the query
- High Performance

## Disadvantages
- Incompleteness of data

# Experiments
First, create required tables and generate some random data by running `create-table.sql` and `seed.sql`.

The database schema used for testing was a basic, and simple cryptocurrency platform. In business scenario, report play as an important role for decision making. Therefore, the test will be experimenting materialzed view for report.

Before start, let's generate bulk dummy data by using the following sql.
```
INSERT INTO transactions (tx_id, amount, wallet_id, created_at)
SELECT md5((random() * 100000000)::text),
    (random() * from generate_series(1, 100000000);
) + 1,
    (
        SELECT id
        from wallet
        order by random()
        LIMIT 1
    ), NOW() + (random() * (NOW() + '150 days' - NOW()))
from generate_series(1, 10000000);
```

The following sql will generate simple daily summary report which consists of transaction count per day.
```
SELECT COUNT(id) as transaction_count, date_trunc('day', created_at) as date from transactions group by(date) order by date desc;
```
Execution plan:
```
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=1743086.62..1943083.50 rows=9999844 width=16) (actual time=8056.381..9973.825 rows=151 loops=1)
   Group Key: (date_trunc('day'::text, created_at))
   ->  Sort  (cost=1743086.62..1768086.23 rows=9999844 width=12) (actual time=8046.697..9113.569 rows=10000000 loops=1)
         Sort Key: (date_trunc('day'::text, created_at)) DESC
         Sort Method: external merge  Disk: 215344kB
         ->  Seq Scan on transactions  (cost=0.00..238635.05 rows=9999844 width=12) (actual time=98.105..3613.442 rows=10000000 loops=1)
 Planning Time: 0.091 ms
 JIT:
   Functions: 7
   Options: Inlining true, Optimization true, Expressions true, Deforming true
   Timing: Generation 1.420 ms, Inlining 10.933 ms, Optimization 58.919 ms, Emission 28.024 ms, Total 99.295 ms
 Execution Time: 9997.982 ms
(12 rows)
```
The query above performance slow because there was lot of rows to scan through. Let's create a materialized view for it.
```
CREATE MATERIALIZED VIEW daily_transaction_summary AS SELECT COUNT(id) as transaction_count, date_trunc('day', created_at) as date from transactions group by(date) order by date DESC;
```
Execution plan for materialzed view:
```
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Seq Scan on daily_transaction_summary  (cost=0.00..2.51 rows=151 width=16) (actual time=0.009..0.022 rows=151 loops=1)
 Planning Time: 0.028 ms
 Execution Time: 0.040 ms
(3 rows)
```
The execution time decreased from 9997.982 ms to 0.040 ms because it just retrive all the data stored, without any filtering, or function execution.

However, if we insert a new transaction for date `2021-12-13`, the result of materialzed view doesn't reflect the new transaction inserted. This can be fixed by running `REFRESH MATERIALIZED VIEW daily_transaction_summary`. But, this will has huge impact on performance as postgres will run the underlying query again, and store the latest result.

It is recommended to create a cronjob, which will refresh the materialzed view at specific time. For example, everyday 12.00 A.M.