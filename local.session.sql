EXPLAIN WITH formatted_user AS (
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