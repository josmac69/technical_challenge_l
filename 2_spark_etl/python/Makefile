.PHONY: start \
	stop \
	show-data \
	psql \
	build-pylint \
	pylint \
	unittest

POSTGRESQL_CONTAINER=my_postgres
POSTGRESQL_USER=myuser
POSTGRESQL_DB=main

PYLINT_CONTAINER=my_pylint

start:
	docker compose up

stop:
	docker compose down

show-data:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DB) \
	-c "SELECT * FROM metrics"

psql:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DB)

build-pylint:
	docker build --progress=plain \
	--no-cache -t $(PYLINT_CONTAINER) \
	-f Dockerfile.pylint .

pylint:
	docker run \
	-v $(PWD):/app \
	$(PYLINT_CONTAINER) \
	/app/script.py

unittest:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	bitnami/spark:3 \
	python3 -m unittest test_script.py
