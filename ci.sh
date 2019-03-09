#!/bin/bash
set -e
set -o pipefail
set -o xtrace

# setup lua
luarocks --lua-version=5.1 install --local moonscript
luarocks --lua-version=5.1 install --local cloud_storage
luarocks --lua-version=5.1 install --local https://luarocks.org/manifests/leafo/lapis-dev-1.rockspec
luarocks --lua-version=5.1 install --local https://raw.githubusercontent.com/moteus/ZipWriter/master/rockspecs/zipwriter-0.1.2-1.rockspec
luarocks --lua-version=5.1 install --local moonrocks
luarocks --lua-version=5.1 install --local https://raw.githubusercontent.com/leafo/tableshape/master/tableshape-dev-1.rockspec
eval $(luarocks --lua-version=5.1 path)

# prepare secrets
cp -r secret_example secret
echo "config 'test', -> logging false" >> config.moon

# build
tup init && tup generate build.sh && ./build.sh
cat $(which busted) | sed 's/\/usr\/bin\/lua5\.1/\/usr\/bin\/luajit/' > busted
chmod +x busted

# start postgres
echo "fsync = off" >> /var/lib/postgres/data/postgresql.conf
echo "synchronous_commit = off" >> /var/lib/postgres/data/postgresql.conf
echo "full_page_writes = off" >> /var/lib/postgres/data/postgresql.conf
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data start -w -t 120'

make init_schema
make migrate
make test_db

# mkdir -p logs
# touch logs/notice.log
# tail -f logs/notice.log &

echo 'user root;' >> nginx.conf

LAPIS_NOTICE_LOG=logs/notice.log ./busted -o utfTerminal
