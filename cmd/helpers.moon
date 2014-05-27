
http = require "socket.http"

assert_request = (...) ->
  body, status, headers = http.request ...
  assert status == 200, "Failed to request #{...}, got #{status}"
  body, status, headers

parse_manifest = (text) ->
  fn = loadstring text
  return nil, "Failed to parse manifest" unless fn

  manif = {}
  setfenv fn, manif
  return nil, "Failed to eval manifest" unless pcall(fn)

  unless manif.repository
    return nil, "Invalid manifest (missing repository)"

  manif

connect_postgres = ->
  db = require "lapis.db"
  config = require("lapis.config").get!
  pg_config = assert config.postgres, "missing postgres configuration"
  logger = require "lapis.logging"

  import Postgres from require "pgmoon"
  pgmoon = Postgres pg_config
  assert pgmoon\connect!

  db.set_backend "raw", (q, ...) ->
    logger.query  q
    assert pgmoon\query q, ...

{ :assert_request, :parse_manifest, :connect_postgres }
