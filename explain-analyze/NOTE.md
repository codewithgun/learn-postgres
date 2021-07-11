# Overview
`EXPLAIN`, is a must learn feature for query tuning. It is used to analyze the execution plan of a query. Then, the query will be optimized using `index`, `materialized view`, or others.

Everytime when submit a query to postgres, the query will go through a series of process stages.

1. Parser
2. Rewrite
3. Planner
4. Execute

### Parser
---
When postgres server received the query, the first thing it does is to build a `query tree` to represent our query. The parser will ensure that all the syntax, and keyword used was valid before it produces the `query tree`. The `query tree` will be feeded to `rewrite` stage.

### Rewrite
---
To-be-study

### Planner
---
Planner played as an important role for query performance. It take the input from `rewrite`, based on the input and data from `pg_statistic`, it determine the most effecient way to produce the result.

For example:
- Should it use index scan, or full table scan ?
- If loop is required, should the result be `materialized` for performance gain?
- Should it go to the `page/block` to get the data, or the information in the index tree was sufficient ?
- and much more

### Execute
---
It use the `execution plan` given by the planner to produce the result. It will go to specific `block/page` of a `heap` to retrieve the `tuples/items`.

# Experiment
Create tables, views by running `create-table.sql` and `create-view.sql`. After that, insert dummy records by running `seed.sql` multiple times.

Let's checkout the execution plan for `SELECT * FROM student`;
```
EXPLAIN SELECT * FROM student;
```
Result: 
```
                        QUERY PLAN                         
-----------------------------------------------------------
 Seq Scan on student  (cost=0.00..17.80 rows=780 width=76)
 ```
 The query plan above shows that, it run `Seq Scan` (loop through all rows) on student table. The estimated rows to loop was 780, and the estimated final processing cost will be 17.80.
 > Reference for cost constant (https://www.postgresql.org/docs/10/runtime-config-query.html#RUNTIME-CONFIG-QUERY-CONSTANTS)

However, when I check the number of row using `SELECT COUNT(id) FROM student`, the total number of row was 52. This is because the execution planner used the data from `pg_statistic` table, but the data in it was out-of-date. Out-of-date statistic might lead to wrong estimation for execution planner, which lead to degraded performance. This can be fixed by running `analyze`, which postgres will update `pg_statistic` about all the tables. 

Now, we check the execution plan again.
```
                       QUERY PLAN                        
---------------------------------------------------------
 Seq Scan on student  (cost=0.00..1.52 rows=52 width=50)
```
The estimation of cost, and rows was accurate now. It is recommended to run a routine maintenance such `analyze`, `vacuum`. But, luckily postgres has `auto analyze` and `auto vacuum` feature enabled by default.

When `explain` and `analyze` combine, it will shows the estimation plan, as well as the actual execution occurred.
```
EXPLAIN ANALYZE SELECT * FROM student;
```
Result:
```
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Seq Scan on student  (cost=0.00..1.52 rows=52 width=50) (actual time=0.007..0.011 rows=52 loops=1)
 Planning Time: 0.034 ms
 Execution Time: 0.023 ms
 ```
 The total time taken for the query above was `0.034` ms + `0.023` ms. `(cost=0.00..1.52 rows=52 width=50)` was the estimation while `(actual time=0.007..0.011 rows=52 loops=1)` was the actual time, rows, and cost for the query execution.

 Let's checkout the execution plan when there was condition involved.
 ```
 EXPLAIN ANALYZE select * from student where id = 1;
 ```
 Result:
 ```
                                            QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Seq Scan on student  (cost=0.00..1.65 rows=1 width=4) (actual time=0.009..0.013 rows=1 loops=1)
   Filter: (id = 1)
   Rows Removed by Filter: 51
 Planning Time: 0.047 ms
 Execution Time: 0.024 ms
 ```
 Hmm, doesn't primary key will be indexed automatically, why postgres is still doing `Seq Scan` ? This is because postgres was smart enough to determine using `index` or `Seq Scan` faster by using data in `pg_statistic` table. This is why an out-of-date statistic will lead to degraded performance as it might causes postgres to build a non effecient execution plan. 

 For example, the actual database row consists of 10000 + rows, but the out-of-date `pg_statistic` causes postgres to use `full-table scan` instead of `index scan`, which has a huge impact on performance.
 
 The case above, `Seq Scan` was choosen because there was only 52 rows in total, and postgres decided that traveling index `b-tree` was much more expensive than `Seq Scan`.

 Now, let's duplicate the number of records by running the query below many times.
 ```
 INSERT INTO student (name, created_at, age) SELECT name, created_at, age FROM student;
 ```
 The `student` table current has `26624` row. And, we run `EXPLAIN ANALYZE select * from student where id = 1;` again. For this round, we are getting different execution plan.
 ```
                                                       QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 Index Scan using student_pkey on student  (cost=0.29..8.30 rows=1 width=50) (actual time=0.006..0.006 rows=1 loops=1)
   Index Cond: (id = 1)
 Planning Time: 0.191 ms
 Execution Time: 0.019 ms
 ```
 Postgres determine that, traveling `b-tree` is much more cheaper than `Seq Scan` as the number of rows was too much. Postgres based on the result in `b-tree` index to retrive the raw results from specific `heap` => `block` => `tuple`.

If we select the columns, which already exists in `b-tree` index, the execution plan will be different.
```
EXPLAIN ANALYZE select id from student WHERE id = 100;
```
Result:
```
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using student_pkey on student  (cost=0.29..4.30 rows=1 width=4) (actual time=0.013..0.014 rows=1 loops=1)
   Index Cond: (id = 100)
   Heap Fetches: 0
 Planning Time: 0.056 ms
 Execution Time: 0.030 ms
 ```
 The planner use `Index Scan` on the previous query, while it used `Index Only Scan` for the current query. This is because, the `id` column already exists in the `b-tree` index. Once postgres travel finish the `b-tree`, it already have the `id` value. Therefore, postgres doesn't require to go to `heap` => `block` => `tuple` to get the other columns (`age`, `name`, `created_at`).