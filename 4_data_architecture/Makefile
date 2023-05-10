.PHONY: start_postgres \
	stop_postgres \
	run_psql \
	run_bash

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
