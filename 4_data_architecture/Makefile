.PHONY: \
	clean \
	build_python \
	pylint \
	run_python \
	unittest \
	start_postgres \
	stop_postgres \
	tables \
	psql

POSTGRESQL_CONTAINER=my_postgres
POSTGRESQL_USER=myuser
POSTGRESQL_PASSWORD=mypassword
POSTGRESQL_DATABASE=main

PYTHON_CONTAINER := my_ml_python
SCRIPT ?= ml_script.py

clean:
	docker ps -aq | xargs -I {} docker rm -f {}

build_python:
	docker build --progress=plain \
	--no-cache -t $(PYTHON_CONTAINER) \
	-f ./Dockerfile .

pylint:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	/bin/bash -c "pylint $(SCRIPT)"

run_python: clean
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	python3 ml_script.py $(ARGS)

unittest:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	python3 -m unittest test_ml_script.py

start_postgres: clean
	docker compose -f docker-compose.yaml up

stop_postgres:
	docker compose -f docker-compose.yaml down

tables:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE) \
	-c "select schemaname, relname, n_live_tup as records from pg_stat_all_tables where schemaname = 'public';"

psql:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE)
