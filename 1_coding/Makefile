.PHONY: clean \
	build \
	run \
	pylint \
	unittest

PYTHON_CONTAINER := my_python
SCRIPT ?= script.py

clean:
	docker ps -aq | xargs -I {} docker rm -f {}

build:
	docker build --progress=plain \
	--no-cache -t $(PYTHON_CONTAINER) \
	-f ./Dockerfile .

run: clean
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	python3 script.py $(ARGS)

pylint:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	/bin/bash -c "pylint $(SCRIPT)"

unittest:
	docker run -it \
	-v $(PWD):/app \
	-w /app \
	$(PYTHON_CONTAINER) \
	python3 -m unittest test_script.py
