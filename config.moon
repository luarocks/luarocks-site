
import config from require "lapis.config"

config {"development", "test", "production", "heroku"}, ->
  tool_version "0.0.1"
  pcall -> include require "secret.init"

config {"development", "test"}, ->
  num_workers 1
  code_cache "off"
  daemon "off"
  notice_log "stderr"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks_dev"

config "production", ->
  num_workers 2
  code_cache "on"

  daemon "on"
  notice_log "logs/notice.log"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks"

config "heroku", ->
  num_workers 4
  code_cache "on"
  port os.getenv "PORT"

  postgresql_url os.getenv "HEROKU_POSTGRESQL_ROSE_URL"
  bucket_name "moonrocks"

