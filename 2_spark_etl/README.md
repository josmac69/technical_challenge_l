# Spark Challenge

## Task

**Exercise overview**
Next exercise is about coding a simple ETL process using Spark. This exercise help us to check out your Spark level at the same time we analyze your coding style. Feel free to use any tool for develop (Notebook, IDE, paper…). You can use the Spark SDK of your choice (preferably Spark 2+) or any other distributed framework like Hadoop/MapReduce, Hive, Pig…

**Exercise goal**
Attach to this document you'll find a “events.csv” file containing users’ actions. Each action has a timestamp and a possible value, either "open" or "close". We would like you to reduce data temporal granularity to 10 minutes, so that there is only one single row for each 10 minutes. Over this temporal aggregation count how many actions of each type there is per minute. After previous calculation, please compute the average number of actions each 10 minutes. Finally, we would like you to compute the top 10 minutes with a bigger amount of "open" action.

Can you do a proposal about how to test this job with unit test, how to test a full pipeline with a integration test and how to release this job on production with data quality check?

## Solution

### Python version

- Python version of the solution is in the directory `python`.

- Use make command inside this directory to operate the solution:
  - `make start` - runs the solution using `docker compose up`
  - `make stop` - stops all running containers after tests
  - `make show-data` - shows the results from the database
  - `make psql` - runs postgresql `psql` client in the container in terminal interactive mode for manual check in the database
  - `make build-pylint` - builds pylint docker image for static code analysis
  - `make pylint` - runs static code analysis using pylint
