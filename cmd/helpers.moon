
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

{ :connect_postgres }
