#!/bin/bash
set -e
set -o pipefail
set -o xtrace

# setup lua
luarocks-5.1 remove --force lapis
luarocks-5.1 install moonscript
luarocks-5.1 install cloud_storage
luarocks-5.1 install https://luarocks.org/manifests/leafo/lapis-dev-1.rockspec
luarocks-5.1 install https://raw.githubusercontent.com/moteus/ZipWriter/master/rockspecs/zipwriter-0.1.2-1.rockspec
luarocks-5.1 install moonrocks
eval $(luarocks-5.1 path)

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

# mkdir logs
# touch logs/notice.log
# tail -f logs/notice.log &

LAPIS_NOTICE_LOG=logs/notice.log ./busted -o utfTerminal
