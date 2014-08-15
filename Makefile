
.PHONY: test test_db lint schema routes

test:
	busted

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


schema:
	lapis exec 'require"schema".make_schema()'

routes:
	lapis exec 'require "cmd.routes"'


