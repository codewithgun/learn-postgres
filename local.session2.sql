EXPLAIN SELECT *
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