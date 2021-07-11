WITH formatted_user AS (
    SELECT id, DATE_TRUNC('day', created_at) AS DATE FROM users
), user_report AS (
    SELECT COUNT(id), date FROM formatted_user GROUP BY date order by date
)

SELECT * FROM user_report WHERE date BETWEEN TO_DATE('01-07-2021', 'DD-MM-YYYY') AND TO_DATE('01-08-2021', 'DD-MM-YYYY');