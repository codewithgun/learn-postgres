# Overview
View, is a logical table in database. It doesn't store `data` or `result` on the disk. The query in the view is run every time when the view is being used in query. Therefore, creating view doesn't yield any performance. In Postgres, the view is `read-only`, any insert, update or delete operation is not allowed to be perform on the view. It is similar to CTE (Common Table Expression). The only difference between them is the view can be referenced by any query/transaction, while CTE only available for that query session.

## Types of view
- Normal view
- Materialized view
- Recursive view

## Advantages
- Simplify complex query
- Show only authorized data to the user based on permission
- Client/System can query data in one request

# Experiment
