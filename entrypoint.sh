eval $(luarocks --lua-version=5.1 path)
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data start -w -t 120'
lapis server
