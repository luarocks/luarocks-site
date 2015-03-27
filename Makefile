
.PHONY: test test_db lint schema routes

test:
	busted

init_schema::
	createdb -U postgres moonrocks
	cat schema.sql | psql -U postgres moonrocks

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

# save a copy of dev database into dev_backup
checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres moonrocks > dev_backup/$$(date +%F_%H-%M-%S).dump

# restore latest dev backup
restore_checkpoint::
	-dropdb -U postgres moonrocks
	createdb -U postgres moonrocks
	pg_restore -U postgres -d moonrocks $$(find dev_backup | grep \.dump | sort -V | tail -n 1)


