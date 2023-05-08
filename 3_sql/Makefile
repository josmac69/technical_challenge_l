.PHONY: start_postgres run_task1 run_task2 run_task3

POSTGRESQL_CONTAINER=my_postgres
POSTGRESQL_USER=myuser
POSTGRESQL_PASSWORD=mypassword
POSTGRESQL_DATABASE=main

start_postgres:
	docker compose -f docker-compose.yaml up

stop_postgres:
	docker compose -f docker-compose.yaml down

run_psql:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE)

run_bash:
	docker exec -it $(POSTGRESQL_CONTAINER) /bin/bash

run_task1:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE) \
	-f /app/task1.sql

run_task2:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE) \
	-f /app/task2.sql

run_task3:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE) \
	-f /app/task3.sql
