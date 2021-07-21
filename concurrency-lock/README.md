# Overview
> Yeah ... today morning I got a call from my project manager, and `double spend` problem happened :(

Concurrency, multiple connection to database happening at the same time. It is great, since it allow multiple request being served at the same time, which provide a smooth and responsive user experience. However, this create issues such as `phantom read`, `non-repeatable read` and `dirty read`. In the business environment, most of the time the program will make decision based on the data stored. Therefore, data `inconsistency` will have huge impact on the business, especially when it related to financial. `Lock` mechanism can be used to solve issues created by concurrency. 

## Issues
| Issue | Description | Happen in Isolation | Source |
| --- | --- | --- | --- |
| Dirty read | Reading uncommitted data | Read uncommitted | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Dirty_reads |
| Non-repeatable read | Different `value` was returned from the same record by same query in a single transaction, due to `update` commit from another transaction | Read committed, Read uncommitted | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Non-repeatable_reads |
| Phantom read | Different `records` was returned from the same query in a single transaction, due to `insert` or `delete` commit from another transaction | Repeatable Reads, Read uncommitted, Read committed | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Phantom_reads |

## Isolation
Isolation control the seperation (isolation) between transactions. We can think as different transaction having different workspace, while isolation control the visibility of query made in the workspace for another workspace.

| Type | Description | Lock |
| --- | --- | --- |
| Read uncommitted | Transaction 1 can read all uncommitted changes made by transaction 2 | No locks |
| Read committed | Transaction 1 can read committed changes made by transaction 2, but no uncommitted changes | Lock on `update` and `delete` |
| Repeatable read | Transaction 1 can only read committed changes (`insert` and `delete`), and the initial `state` of existing rows when transaction 1 begin | Lock on `update` and `delete`, immediately get error if another transaction commited `update` or `delete` |
| Serializable | Same as `Repeatable read` | Same as `Repeatable read`, with addition of immediate error when there was `dependencies` between transaction. Eg (`INSERT INTO coins (name) SELECT name FROM coins`)


> In PostgreSQL READ UNCOMMITTED is treated as READ COMMITTED. (https://www.postgresql.org/docs/current/sql-set-transaction.html)

> In PostgreSQL, `phantom read` not allowed. Therefore, it allow us to see only data committed before the transaction begin. (https://www.postgresql.org/docs/9.5/transaction-iso.html)

## Solution
`Lock` can be used to solve the issues above, by sacrificing the performance gain from concurrency by controlling the access to the `row` or `table`.
## Types of Lock
| Lock | Description |
| --- | --- |
| Exclusive Lock | Only the transaction accquired the lock can access it (`select`, `update`, `delete`) |
| Shared lock | Only the transaction accquired the lock can `update` or `delete` it. The other transactions still can read it |

## Lock level
| Level | Description |
| --- | --- |
| Row | Lock on `row`, other rows still can be access
| Table | Lock on `table`, all rows in the table cannot be access

In PostgreSQL, `exclusive row-level lock` is automatically applied when the row is updated or deleted. (https://www.postgresql.org/docs/9.1/explicit-locking.html)

# Experiments
Since I got `double spending` issue today. Therefore, I will be experimenting on `lock` as a solution for double spending issue. 

Create tables and seed some dummy data by running `create-table.sql` and `seed.sql`.

The wallet balance before simulating withdrawal spam.
```
postgres=# select * from wallets;
 id |         balance          |     name     
 ----+--------------------------+--------------
 2 | 100.00000000000000000000 | codewithlove
 1 | 100.00000000000000000000 | codewithgun
```

Now, simulate withdrawal spam by running the code below in the terminal.
```
ts-node withdraw-without-lock.ts
```
The code will spam withdrawal 100 times, with the amount of 50 for each withdrawal. There will be only 1 withdrawal success, while the others failed due to insufficient balance. Therefore, the expected result should be as below.
```
postgres=# select * from wallets;
 id |         balance          |     name     
 ----+--------------------------+--------------
 2 | 100.00000000000000000000 | codewithlove
 1 |  50.00000000000000000000 | codewithgun
```
But, when query from database, the result below was shown.
```
postgres=# select * from wallets;
 id |          balance          |     name     
 ----+---------------------------+--------------
 2 |  100.00000000000000000000 | codewithlove
 1 | -850.00000000000000000000 | codewithgun
```
This is really bad as it causes financial lost to the company.

Now, let's reset back the balance by running the query below.
```
UPDATE wallets SET balance = 100;
```
Then, we run the another simulation withdrawal spam program, with `exclusive row-level lock` implemented.
```
ts-node concurrency-lock/withdraw-with-lock.ts 
```
Let's check the result in database.
```
postgres=# select * from wallets;
 id |         balance          |     name     
 ----+--------------------------+--------------
  1 |  50.00000000000000000000 | codewithgun
  2 | 100.00000000000000000000 | codewithlove
```
Nice. The result was same as we expected.

In summary, depends on the `consistency` of the data, we should decide the right `lock level` and `lock type`. The most common scenario for `exclusive lock` I knew was double spending and double booking. While, the common scenario for `shared lock` I knew was report generation or account closing (accounting term). For example, everyday midnight time, you can view bank details, but no transaction can be made.