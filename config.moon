
import config from require "lapis.config"

config "development", ->
  num_workers 1
  code_cache "off"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks_test"

config "heroku", ->
  num_workers 4
  code_cache "on"
  port os.getenv "PORT"

  postgresql_url os.getenv "HEROKU_POSTGRESQL_ROSE_URL"
  bucket_name "world_class_dad"

