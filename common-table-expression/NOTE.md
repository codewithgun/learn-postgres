# Overview
Common table expression (CTE) is a temporary result set, which only live within this query session. You may think it as a variable, which store value in programming. CTE, is similar to view. The only difference between `view` and `cte` is postgres store the definition of the view in physical disk, while `cte` doesn't. Therefore, `cte` can only be used by the query defined it, while `view` is available for all the authorized user.

### Advantages
- Simplify complex query
- Can be reference/reuse in subquery

# Experiment
Create the required tables, view and insert some dummy data by running `create-table.sql`, `create-view.sql` and `seed.sql`.

Let's say, we could like to get total number of user registered daily between 2 date.
```
SELECT *
FROM (
        SELECT COUNT(id) as count,
            DATE_TRUNC('day', created_at) AS DATE
        FROM users u
        WHERE DATE_TRUNC('day', created_at) BETWEEN TO_DATE('01-07-2021', 'DD-MM-YYYY') AND TO_DATE('01-08-2021', 'DD-MM-YYYY')
        GROUP BY date
        UNION
        (
            SELECT *
            FROM (
                    SELECT 0 AS count,
                        GENERATE_SERIES(
                            TO_DATE('01-07-2021', 'DD-MM-YYYY'),
                            TO_DATE('01-08-2021', 'DD-MM-YYYY'),
                            interval '1 day'
                        ) AS date
                ) as c
            WHERE c.date NOT IN(
                    SELECT DATE_TRUNC('day', created_at) AS DATE
                    FROM users u
                    WHERE DATE_TRUNC('day', created_at) BETWEEN TO_DATE('01-07-2021', 'DD-MM-YYYY') AND TO_DATE('01-08-2021', 'DD-MM-YYYY')
                    GROUP BY date
                )
        )
    ) AS final_report ORDER BY final_report.date;
```
Result
```
 count |          date          
-------+------------------------
     0 | 2021-07-01 00:00:00+00
     0 | 2021-07-02 00:00:00+00
     0 | 2021-07-03 00:00:00+00
     0 | 2021-07-04 00:00:00+00
     0 | 2021-07-05 00:00:00+00
     0 | 2021-07-06 00:00:00+00
     0 | 2021-07-07 00:00:00+00
     0 | 2021-07-08 00:00:00+00
     0 | 2021-07-09 00:00:00+00
     0 | 2021-07-10 00:00:00+00
     0 | 2021-07-11 00:00:00+00
     0 | 2021-07-12 00:00:00+00
     0 | 2021-07-13 00:00:00+00
     1 | 2021-07-14 00:00:00+00
     3 | 2021-07-15 00:00:00+00
     2 | 2021-07-16 00:00:00+00
     0 | 2021-07-17 00:00:00+00
     0 | 2021-07-18 00:00:00+00
     0 | 2021-07-19 00:00:00+00
     0 | 2021-07-20 00:00:00+00
     1 | 2021-07-21 00:00:00+00
     2 | 2021-07-22 00:00:00+00
     0 | 2021-07-23 00:00:00+00
     1 | 2021-07-24 00:00:00+00
     0 | 2021-07-25 00:00:00+00
     0 | 2021-07-26 00:00:00+00
     0 | 2021-07-27 00:00:00+00
     1 | 2021-07-28 00:00:00+00
     2 | 2021-07-29 00:00:00+00
     1 | 2021-07-30 00:00:00+00
     2 | 2021-07-31 00:00:00+00
     0 | 2021-08-01 00:00:00+00
(32 rows)
```
Even though the query above provide what we needed, but the query itself is a mess. It is hard to debug, read and consists of duplication. We could rewrite the above query using CTE.
```
WITH formatted_user AS (
    SELECT id,
        DATE_TRUNC('day', created_at) AS DATE
    FROM users
),
start_date AS (
    SELECT TO_DATE('01-07-2021', 'DD-MM-YYYY') AS start_date
),
end_date AS (
  SELECT TO_DATE('01-08-2021', 'DD-MM-YYYY') AS end_date
),
user_report AS (
    SELECT COUNT(id) as count,
        date
    FROM formatted_user
    GROUP BY date
),
ranged_date_user_report AS (
    SELECT *
    FROM user_report
    WHERE date BETWEEN (SELECT * FROM start_date)AND (select * from end_date)
),
full_ranged_report AS (
    SELECT 0 AS count, GENERATE_SERIES((SELECT * FROM start_date), (SELECT * from end_date), interval '1 day') AS date
),
final_report AS (
    SELECT * FROM ranged_date_user_report UNION (
        SELECT * FROM full_ranged_report WHERE date NOT IN (SELECT date FROM ranged_date_user_report)
    )
)

SELECT * FROM final_report ORDER BY date;
```
Both of them produces the same results. But with `CTE`, the query is much more readable and maintainable.