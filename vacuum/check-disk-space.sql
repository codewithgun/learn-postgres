SELECT relname AS "table_name",
    pg_size_pretty(pg_table_size(pgc.oid)) AS "space_used"
FROM pg_class AS pgc
    LEFT JOIN pg_namespace AS pgns ON (pgns.oid = pgc.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
    AND nspname !~ '^pg_toast'
    AND relkind IN ('r')
ORDER BY pg_table_size(pgc.oid) DESC
LIMIT 1;