INSERT INTO student (name, created_at, age)
SELECT x.a,
    y.b,
    z.c
FROM (
        SELECT *
        FROM random_name
    ) as x,
    (
        SELECT *
        FROM random_date
    ) as y,
    (
        SELECT *
        FROM random_age
    ) as z;