
.PHONY: test test_db lint schema routes

test:
	busted

init_schema::
	createdb -U postgres itchio
	cat schema.sql | psql -U postgres itchio

migrate::
	lapis migrate
	make schema.sql

schema.sql::
	pg_dump -s -U postgres moonrocks > schema.sql
	pg_dump -a -t lapis_migrations -U postgres moonrocks >> schema.sql

test_db:
	-dropdb -U postgres moonrocks_test
	createdb -U postgres moonrocks_test
	pg_dump -s -U postgres moonrocks | psql -U postgres moonrocks_test

prod_db::
	-dropdb -U postgres moonrocks_prod
	createdb -U postgres moonrocks_prod
	pg_restore -U postgres -d moonrocks_prod $$(find /home/leafo/bin/backups/ | grep moonrocks | sort -V | tail -n 1)

lint:
	moonc -l $$(git ls-files | grep '\.moon$$' | grep -v config.moon)

routes:
	lapis exec 'require "cmd.routes"'


