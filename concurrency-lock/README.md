# Overview
> Yeah ... today morning I got a call from my project manager, and `double spend` problem happened :(

Concurrency, multiple connection to database happening at the same time. It is great, since it allow multiple request being served at the same time, which provide a smooth and responsive user experience. However, this create issues such as `phantom read`, `non-repeatable read` and `dirty read`. In the business environment, most of the time the program will make decision based on the data stored. Therefore, data `inconsistency` will have huge impact on the business, especially when it related to financial. `Lock` mechanism can be used to solve issues created by concurrency. 

## Issues
| Issue | Description | Happen in Isolation | Source |
| --- | --- | --- | --- |
| Dirty read | Reading uncommitted data | Read uncommitted | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Dirty_reads |
| Non-repeatable read | Different `value` was returned from the same query in a single transaction, due to `update` commit from another transaction | Read committed, Read uncommitted | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Non-repeatable_reads |
| Phantom read | Different `records` was returned from the same query in a single transaction, due to `insert` or `delete` commit from another transaction | Repeatable Reads, Read uncommitted, Read committed | https://en.wikipedia.org/wiki/Isolation_(database_systems)#Phantom_reads |

## Isolation
| Type | Description | Lock |
| --- | --- | --- |
| Read uncommitted | Transaction 1 can read all uncommitted changes made by transaction 2 | Lock on `update` and `delete` |
| Read committed | Transaction 1 can read committed changes made by transaction 2, but no uncommitted changes | Lock on `update` and `delete` |

## Solution
`Lock` can be used to solve the issues above, by sacrificing the performance provided by concurrency by controlling the access to the `row` or `table`.