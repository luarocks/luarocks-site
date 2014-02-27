
.PHONY: test test_db lint schema routes

test:
	busted

test_db:
	-dropdb -U postgres moonrocks_test
	createdb -U postgres moonrocks_test
	pg_dump -s -U postgres moonrocks | psql -U postgres moonrocks_test


lint:
	moonc -l $$(git ls-files | grep '\.moon$$' | grep -v config.moon)


schema:
	lapis exec 'require"schema".make_schema()'

routes:
	lapis exec 'require "cmd.routes"'


