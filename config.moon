
import config from require "lapis.config"

config { "development", "test", "production", "staging" }, ->
  app_name "MoonRocks"
  track_exceptions true

  redis_host "127.0.0.1"
  redis_port 6379

  tool_version "1.0.0"
  pcall -> include require "secret.init"

  postgres {
    backend: "pgmoon"
    user: "postgres"
    password: "1234"
    database: "moonrocks"
  }

  host "localhost:8080"

  systemd {
    name: "luarocks"
    user: true
  }

config { "development", "test" }, ->
  num_workers 1
  code_cache "off"
  daemon "off"
  notice_log "stderr"

  bucket_name "moonrocks_dev"

config "test", ->
  code_cache "on"

config { "production", "staging" }, ->
  num_workers 2
  code_cache "on"

  enable_https true

  admin_email "leafot@gmail.com"

  daemon "on"
  notice_log "logs/notice.log"
  logging false

  bucket_name "moonrocks"

  host "luarocks.org"

config "staging", ->
  port 8081
  num_workers 1
  daemon "off"
  notice_log "stderr"

config "test", ->
  postgres {
    database: "moonrocks_test"
  }

