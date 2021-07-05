# Overview
Vacuum is a feature of postgresql, which used to clean up disk spaces by removing dead tuples (rows). 

This is because the rows deleted or updated, are not physically being removed from the disk. Instead, those rows are mark as `deleted`.

There are 2 types of vacuum
| Type | Description | Advantage | Disadvantage |
| -----| ----------- | --------- | ------------ |
| Full | Full vacuum will reclaim your disk space by physically removing the dead tuples. | Save disk space | Slow, and lock on table |
| Normal | Normal vacuum will not physically remove the dead tuples, but mark the row to be reuseable by any insert or update statement | Fast | Do not reclaim physical disk space |

> Do not run full vacuum on production database during peak hour as it will downgrade the performance dramatically

## Experiment
First, we enable `pageinsepct` extension by running
```
CREATE EXTENSION pageinsepct;
```
This extension allows you to inspect the low level of data, such as `heap`, `page`, and `tuple`.

Create a table for testing by using the SQL below.
``` 
CREATE TABLE STUDENT (
    id SERIAL NOT NULL,
    name TEXT
); 
```
After table creation, we execute the query below.
```
SELECT ctid, xmin, xmax, id, name FROM student;
```
After running the query, you should get `0` rows returned because the table was empty.

| Column | Description |
| ------ | ----------- |
| ctid | The physical location of the row version (block, tuple) |
| xmin | Minimum transaction id |
| xmax | Maximum transaction id |

`xmin` indicate the transaction id that created the row (ctid), while `xmax` indicate the transaction id which deleted, updated (because postgresql remove the row and then insert a new row again) or locked by another transaction id. If the `xmax` value was `0`, it means that the row was not deleted.

Insert a dummy row into the table.
```
INSERT INTO student (name) VALUES(random()::text);
```
Let's check the `xmin` and `xmax` again.
| ctid | xmin | xmax | student_id |
| ---- | ---- | ---- | ---------- |
| (0,1) | 564 | 0 | 1 |
The table shows that we have `1` row, which created at transaction with id `564`.

Now, we insert 4 more rows into the table and check the `xmin` and `xmax` again.
| ctid | xmin | xmax | student_id |
| ---- | ---- | ---- | ---------- |
| (0,1) | 564 | 0 | 1 |
| (0,2) | 565 | 0 | 2 |
| (0,3) | 566 | 0 | 3 |
| (0,4) | 567 | 0 | 4 |
| (0,5) | 568 | 0 | 5 |

Create 2 different transaction by launching query, run query 1 then query 2.
### Query 1
```
BEGIN;
SELECT txid_current();
DELETE FROM student WHERE id = 1;
```
### Query 2
```
SELECT ctid, xmin, xmax, id, name FROM student;
```
### Result (Query 2)
| ctid | xmin | xmax | student_id |
| ---- | ---- | ---- | ---------- |
| (0,1) | 564 | 603 | 1 |
| (0,2) | 565 | 0 | 2 |
| (0,3) | 566 | 0 | 3 |
| (0,4) | 567 | 0 | 4 |
| (0,5) | 568 | 0 | 5 |

We find out that the xmax value was the result of `txid_current()` of query 1. In the scenario above, it is used to indicate that the tuple is being `locked` by the query 1. 

If you try to update that row from query 2, your query will hang until query 1 commit or rollback. After query 1 commit or rollback, if you run `SELECT ctid, xmin, xmax, id, name FROM student` again, you will find out that the name of the student has been updated, but the row is having new `ctid (block,tuple)` value and new xmin and xmax with `0`.

### Result (UPDATE on query 2)

> UPDATE student SET name = '1' WHERE id = 1;

| ctid | xmin | xmax | student_id |
| ---- | ---- | ---- | ---------- |
| (0,2) | 565 | 0 | 2 |
| (0,3) | 566 | 0 | 3 |
| (0,4) | 567 | 0 | 4 |
| (0,5) | 568 | 0 | 5 |
| (0,6) | 605 | 0 | 1 |

Instead of updating the record, postgres `remove` it and `insert` a new row again. This is why the `update` operation is expensive in postgres. And, the `dead tuple` still exists on the disk even though it didn't show out in the query.

Another scenario is the `xmax` indicate that the tuple has been deleted in the past transaction, or is being deleting.

### Query 1
```
BEGIN;
SELECT txid_current();
DELETE FROM student WHERE id = 1;
ROLLBACK;
```
### Query 2
```
SELECT ctid, xmin, xmax, id, name FROM student;
```
Without performing any DML (Data manipulation language) on query 2, you will find out that only the `xmax` of the row being updated.

### Result (Query 2)
| ctid | xmin | xmax | student_id |
| ---- | ---- | ---- | ---------- |
| (0,2) | 565 | 0 | 2 |
| (0,3) | 566 | 0 | 3 |
| (0,4) | 567 | 0 | 4 |
| (0,5) | 568 | 0 | 5 |
| (0,6) | 605 | 607 | 1 |

Here is a good summary on `xmax` value from [stackoverflow](https://stackoverflow.com/questions/49695279/why-xmax-system-column-in-postgres-table-is-not-zero-for-non-deleted-row)

Let's dive to low level.

Reset all the data to initial state by dropping the table and inserting dummy records into it again.

Before running `update` and `delete`, analyze the low level data of student table by running the query below.

```
SELECT t_xmin, t_xmax, tuple_data_split('public.student'::regclass, t_data, t_infomask, t_infomask2, t_bits) FROM heap_page_items(get_raw_page('public.student', 0));
```
| t_xmin | t_xmax | tuple_data_split |                        
| ------ | ------ | ---------------- |
 611 | 0 | {"\\x01000000","\\x27302e38393631343938313532353131383836"}
 612 | 0 | {"\\x02000000","\\x27302e37393630323238323034303631353739"}
 613 | 0 | {"\\x03000000","\\x29302e3238303631383438373835353735303934"}
 614 | 0 | {"\\x04000000","\\x27302e36313635393133363133363435323733"}
 615 | 0 | {"\\x05000000","\\x27302e38353837383139323435353835323434"}

The table above shows the 5 dummy records I generated, as well as it's binary representation in the heap.
```
SELECT relname, n_dead_tup FROM pg_stat_user_tables where relname = 'student';
```
| relname | n_dead_tup |
| ------- | ---------- |
| student | 0 |

The result shows that there are `0` dead tuples in student table;

Now, update one of the student check the low level data of the student table again.

| t_xmin | t_xmax | tuple_data_split |                        
| ------ | ------ | ---------------- |
 611 | 616 | {"\\x01000000","\\x27302e38393631343938313532353131383836"}
 612 | 0 | {"\\x02000000","\\x27302e37393630323238323034303631353739"}
 613 | 0 | {"\\x03000000","\\x29302e3238303631383438373835353735303934"}
 614 | 0 | {"\\x04000000","\\x27302e36313635393133363133363435323733"}
 615 | 0 | {"\\x05000000","\\x27302e38353837383139323435353835323434"}
 616 | 0 | {"\\x01000000","\\x0531"}

 The result shows that the `update` query marked the record was deleted at transaction id `616`, and at the same time, a new record was created (t_xmin `616`)

 Let's try with `delete` query
| t_xmin | t_xmax | tuple_data_split |                        
| ------ | ------ | ---------------- |
 611 | 616 | {"\\x01000000","\\x27302e38393631343938313532353131383836"}
 612 | 617 | {"\\x02000000","\\x27302e37393630323238323034303631353739"}
 613 | 0 | {"\\x0300000","\\x29302e3238303631383438373835353735303934"}
 614 | 0 | {"\\x04000000","\\x27302e36313635393133363133363435323733"}
 615 | 0 | {"\\x05000000","\\x27302e38353837383139323435353835323434"}
 616 | 0 | {"\\x01000000","\\x0531"}

 Based on the result, we can see that the row was not physically deleted, but was marked as `deleted` by transaction id 617.

 If we check for number of `dead tuples`, there should be 2. One is from the `update`, another was from the `delete` query.

```
 SELECT relname, n_dead_tup FROM pg_stat_user_tables;
```
 | relname | n_dead_tup |
 | --- | --- |
 | student | 2 |

 Finally, let's try out the `vacuum` feature of postgres.

 Firstly, we will run a `normal` vacuum. We
 ```
 VACUUM;
 ```
After normal `vacuum`, the number of `dead tuples` in student table should be `0` now. But, they were still physically exists on the disk when we check the low level data of student table.

| t_xmin | t_xmax | tuple_data_split |                        
| ------ | ------ | ---------------- |
|   |   |   |
|   |   |   |
| 613 | 0 | {"\\x0300000","\\x29302e3238303631383438373835353735303934"}
| 614 | 0 | {"\\x04000000","\\x27302e36313635393133363133363435323733"}
| 615 | 0 | {"\\x05000000","\\x27302e38353837383139323435353835323434"}
| 616 | 0 | {"\\x01000000","\\x0531"}

The 2 rows that was normal `vacuum` still exists, but with empty value for `t_xmin`, `t_xmax` and `tuple_data_split`.

Next, let's try full `vacuum`
```
VACUUM FULL;
```
After full `vacuum`, the 2 rows was `truly` removed as shown on the table below.
| t_xmin | t_xmax | tuple_data_split |                        
| ------ | ------ | ---------------- |
| 613 | 0 | {"\\x0300000","\\x29302e3238303631383438373835353735303934"}
| 614 | 0 | {"\\x04000000","\\x27302e36313635393133363133363435323733"}
| 615 | 0 | {"\\x05000000","\\x27302e38353837383139323435353835323434"}
| 616 | 0 | {"\\x01000000","\\x0531"}

In summary, normal `vacuum` should be run periodically to ensure disk spaces. Luckily, postgres come with `auto vacuum` feature. However, some of the database administrator still prefer to run `vacuum` by themselves as `auto vacuum` will kick-in only when the condition meet.

## Useful links
- https://www.percona.com/blog/2018/08/06/basic-understanding-bloat-vacuum-postgresql-mvcc/
- https://www.shubhamdipt.com/blog/how-to-clean-dead-tuples-and-monitor-postgresql-using-vacuum/
- https://stackoverflow.com/questions/49695279/why-xmax-system-column-in-postgres-table-is-not-zero-for-non-deleted-row
- https://www.cybertec-postgresql.com/en/whats-in-an-xmax/
- https://www.youtube.com/watch?v=rsRgFhZHGLo&t=54s