
import config from require "lapis.config"

config { "development", "test", "production", "staging" }, ->
  app_name "MoonRocks"
  track_exceptions true

  tool_version "0.0.1"
  pcall -> include require "secret.init"

  postgres {
    backend: "pgmoon"
    user: "postgres"
    database: "moonrocks"
  }

  host "localhost:8080"


config { "development", "test" }, ->
  num_workers 1
  code_cache "off"
  daemon "off"
  notice_log "stderr"

  bucket_name "moonrocks_dev"

config { "production", "staging" }, ->
  num_workers 2
  code_cache "on"

  enable_https true

  admin_email "leafot@gmail.com"

  daemon "on"
  notice_log "logs/notice.log"

  bucket_name "moonrocks"

  host "rocks.moonscript.org"

config "staging", ->
  port 8081
  num_workers 1
  daemon "off"
  notice_log "stderr"

config "test", ->
  postgres {
    database: "moonrocks_test"
  }

