
import config from require "lapis.config"

config {"development", "production", "heroku"}, ->
  tool_version "0.0.1"
  pcall -> include require "secret.init"

config "development", ->
  num_workers 1
  code_cache "off"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks_dev"

config "production", ->
  num_workers 2
  code_cache "on"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks"

config "heroku", ->
  num_workers 4
  code_cache "on"
  port os.getenv "PORT"

  postgresql_url os.getenv "HEROKU_POSTGRESQL_ROSE_URL"
  bucket_name "moonrocks"

