.PHONY: start stop psql

start:
	docker compose up

stop:
	docker compose down

psql:
	docker exec -it my_postgres psql -U myuser -d main
