.PHONY: clean \
	start \
	stop \
	show-data \
	psql \
	build-pylint \
	pylint \
	build-unittest \
	unittest

POSTGRESQL_CONTAINER=my_postgres
POSTGRESQL_USER=myuser
POSTGRESQL_DB=main

PYLINT_CONTAINER=my_pylint
PYTHON_SCRIPT ?= script.py

clean:
	docker ps -aq | xargs -I {} docker rm -f {}

start: stop clean
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
	/app/$(PYTHON_SCRIPT)

build-unittest:
	docker build --progress=plain \
	--no-cache -t my_spark_unittest \
	-f Dockerfile.unittest .

unittest:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	my_spark_unittest \
	-m unittest test_script.py
