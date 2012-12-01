
db = require "lapis.nginx.postgres"

import concat from table
append_all = (t, ...) ->
  for i=1, select "#", ...
    t[#t + 1] = select i, ...

extract_options = (cols) ->
  options = {}
  cols = for col in *cols
    if type(col) == "table"
      for k,v in pairs col
        options[k] = v
      continue
    col

  cols, options

create_table = (name, columns) ->
  buffer = {"CREATE TABLE IF NOT EXISTS #{db.escape_identifier name} ("}
  add = (...) -> append_all buffer, ...

  for i, c in ipairs columns
    add "\n  "
    if type(c) == "table"
      name, kind = unpack c
      add db.escape_identifier(name), " ", kind
    else
      add c

    add "," unless i == #columns

  add "\n" if #columns > 0

  add ");"
  db.query concat buffer


create_index = (tname, ...) ->
  columns, options = extract_options {...}

  buffer = {"CREATE"}
  append_all buffer, " UNIQUE" if options.unique
  append_all buffer, " INDEX ON #{db.escape_identifier tname} ("

  for i, col in ipairs columns
    append_all buffer, col
    append_all buffer, ", " unless i == #columns

  append_all buffer, ");"
  db.query concat buffer

destroy_table = (tname) ->
  db.query "DROP TABLE IF EXISTS #{db.escape_identifier tname};"

make_schema = ->
  serial = "serial NOT NULL"
  varchar = "character varying(255) NOT NULL"
  varchar_nullable = "character varying(255)"
  text = "text NOT NULL"
  text_nullable = "text"
  time = "timestamp without time zone NOT NULL"
  integer = "integer NOT NULL DEFAULT 0"
  foreign_key = "integer NOT NULL"

  --
  -- Users
  --
  create_table "users", {
    {"id", serial}
    {"username", varchar}
    {"encrypted_password", varchar}
    {"email", varchar}
    {"slug", varchar}
    {"flags", integer}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "users", "email", unique: true
  create_index "users", "username", unique: true
  create_index "users", "slug", unique: true
  create_index "users", "flags"

  -- --
  -- -- UserSessions
  -- --
  -- create_table "user_sessions", {
  --   {"user_id", foreign_key}
  --   {"session_key", varchar}
  --   {"ip_address", varchar}
  --   {"created_at", time}

  --   "PRIMARY KEY (user_id, session_key)"
  -- }

  --
  -- Rocks
  --
  create_table "rocks", {
    {"id", serial}
    {"user_id", foreign_key}
    {"name", varchar}
    {"downloads", integer}
    {"current_version_id", foreign_key}

    {"summary", varchar_nullable}
    {"description", text_nullable}

    {"license", varchar_nullable}
    {"homepage", varchar_nullable}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "rocks", "user_id"
  create_index "rocks", "user_id", "name", unique: true
  create_index "rocks", "downloads"

  --
  -- Versions
  --
  create_table "versions", {
    {"id", serial}
    {"rock_id", foreign_key}
    {"version_name", varchar}
    {"rockspec_url", varchar}
    {"rock_url", varchar_nullable}
    {"downloads", integer}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "versions", "rock_id", "version_name", unique: true
  create_index "versions", "downloads"

  --
  -- Depedencies
  --
  create_table "dependencies", {
    {"rock_id", foreign_key}
    {"dependency", varchar}
    {"full_dependency", varchar}

    "PRIMARY KEY (rock_id, dependency)"
  }

  --
  -- Manifests
  --
  create_table "manifests", {
    {"id", serial}
    {"name", varchar}

    "PRIMARY KEY (id)"
  }

  --
  -- ManifestRocks
  --
  create_table "manifest_rocks", {
    {"manifest_id", foreign_key}
    {"rock_id", foreign_key}
    {"rock_name", varchar}

    "PRIMARY KEY (manifest_id, rock_id)"
  }

  create_index "manifest_rocks", "manifest_id", "rock_name", unique: true


destroy_schema = ->
  tbls = {
    "users", "rocks", "versions", "dependencies",
    "manifests", "manifest_rocks"
  }

  for t in *tbls
    drop_table t


if ... == "test"
  db.query = print
  make_schema!

{ :make_schema, :destroy_schema }


