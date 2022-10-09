SHELL := /bin/bash
CURRENT_DB=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get().postgres.database)')
CURRENT_ENVIRONMENT=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get()._name)')

.PHONY: test test_db lint schema routes vendor_js

test:
	busted

install_deps::
	luarocks build --only-deps --lua-version=5.1 --local

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
	test $(CURRENT_ENVIRONMENT) = development
	-dropdb -U postgres moonrocks_test
	createdb -U postgres moonrocks_test
	pg_dump -s -U postgres $(CURRENT_DB) | psql -U postgres moonrocks_test

prod_db::
	-dropdb -U postgres moonrocks_prod
	createdb -U postgres moonrocks_prod
	pg_restore -U postgres -d moonrocks_prod $$(find /home/leafo/bin/backups/ | grep moonrocks | sort -V | tail -n 1)

lint:
	git ls-files | grep '\.moon$$' | grep -v config.moon | grep -v secret_example/ | xargs -n 100 moonc -l

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

vendor_js:
	npm install
	cp node_modules/d3/build/d3.min.js static/lib
	cp node_modules/jquery/dist/jquery.min.js static/lib
	cp node_modules/selectize/dist/js/standalone/selectize.min.js static/lib
	cp node_modules/selectize/dist/css/selectize.css static/lib

annotate_models:
	lapis annotate $$(find models -type f | grep -v /shapes/ | grep moon$$)

zipserver-dev::
	zipserver -config configs/zipserver-dev.json

