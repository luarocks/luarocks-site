
import config from require "lapis.config"

config { "development", "test", "production", "staging" }, ->
  app_name "MoonRocks"
  track_exceptions true

  tool_version "0.0.1"
  pcall -> include require "secret.init"

config { "development", "test" }, ->
  num_workers 1
  code_cache "off"
  daemon "off"
  notice_log "stderr"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks_dev"

config { "production", "staging" }, ->
  num_workers 2
  code_cache "on"

  admin_email "leafot@gmail.com"

  daemon "on"
  notice_log "logs/notice.log"

  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks"
  bucket_name "moonrocks"

config "staging", ->
  port 8080
  num_workers 1
  daemon "off"
  notice_log "stderr"

config "test", ->
  postgresql_url "postgres://postgres:@127.0.0.1/moonrocks_test"

