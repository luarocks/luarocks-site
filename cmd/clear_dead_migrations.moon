db = require "lapis.db"

migrations = require "migrations"
current = db.query "select name from lapis_migrations"

for {:name} in *current
  continue if migrations[tonumber name]
  db.query "delete from lapis_migrations where name = ?", name

