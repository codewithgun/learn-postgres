# Overview
Common table expression (CTE) is a temporary result set, which only live within this query session. You may think it as a variable, which store value in programming. CTE, is similar to view. The only difference between `view` and `cte` is postgres store the definition of the view in physical disk, while `cte` doesn't. Therefore, `cte` can only be used by the query defined it, while `view` is available for all the authorized user.

### Advantages
- Simplify complex query
- Can be reference/reuse in subquery

# Experiment
Create the required tables, view and insert some dummy data by running `create-table.sql`, `create-view.sql` and `seed.sql`.

