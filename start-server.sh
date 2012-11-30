#!/bin/sh
ROOT=$(pwd)
PORT=8080 HEROKU_POSTGRESQL_ROSE_URL="postgres://postgres:@127.0.0.1/moonrocks" PATH="$ROOT/../bin:/usr/local/openresty/nginx/sbin:$PATH" start_nginx.sh "nginx.conf" "$ROOT"
