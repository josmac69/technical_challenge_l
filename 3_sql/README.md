# SQL Challenge

## Task

You can write the SQL query or the code necessary to produce the required results.

IMPRESSIONS

| Product_id | click | date |
| --- | --- | --- |
| 1002313003 | true |2018-07-10 |
| 1002313002 | false | 2018-07-10 |

PRODUCTS
| Product_id | category_id | price |
| --- | --- | --- |
| 1002313003 | 1 | 10 |
| 1002313002 | 2 | 15 |


PURCHASES
| Product_id | user_id | date |
| --- | --- | --- |
| 1002313003 | 1003431 | 2018-07-10 |
| 1002313002 | 1003432 | 2018-07-11 |

1. Given an IMPRESSIONS table with product_id, click (an indicator that the product was clicked), and date, write a query that will tell you the click-through-rate of each product by month
2. Given the above tables write a query that depict the top 3 performing categories in terms of click through rate.
3. Click-through-rate by price tier (0-5, 5-10, 10-15, >15)

## Solution
* I used PostgreSQL database running in Docker container.
* Using the example above, I generated code and data for the tables.
* I created also SQL queries for the tasks.
* All commands are wrapped in Makefile - usage:
  * `make start_postgres` - start PostgreSQL database in Docker container
  * `make stop_postgres` - stop PostgreSQL database in Docker container
  * `make run_psql` - run PostgreSQL client in Docker container in terminal in interactive mode for manual queries
  * `make run_bash` - run bash shell in Docker container in terminal in interactive mode for manual checks if necessary
  * `make run_task1` - run SQL query for task 1 and print results
  * `make run_task2` - run SQL query for task 2 and print results
  * `make run_task3` - run SQL query for task 3 and print results
