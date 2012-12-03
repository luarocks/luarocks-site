
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

entity_exists = (name) ->
  name = db.escape_literal name
  res = unpack db.select "COUNT(*) as c from pg_class where relname = #{name}"
  res.c > 0

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
  parts = [p for p in *{tname, ...} when type(p) == "string"]
  index_name = concat(parts, "_") .. "_idx"
  return if entity_exists index_name

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
  boolean = "boolean NOT NULL"

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
  -- Modules
  --
  create_table "modules", {
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

  create_index "modules", "user_id"
  create_index "modules", "user_id", "name", unique: true
  create_index "modules", "downloads"

  --
  -- Versions
  --
  create_table "versions", {
    {"id", serial}
    {"module_id", foreign_key}

    {"version_name", varchar}

    {"rockspec_key", varchar}
    {"rockspec_fname", varchar}

    {"downloads", integer}
    {"rockspec_downloads", integer}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "versions", "module_id", "version_name", unique: true
  create_index "versions", "downloads"
  create_index "versions", "rockspec_key", unique: true
  create_index "versions", "rockspec_fname"

  --
  -- Rocks
  --
  create_table "rocks", {
    {"id", serial}
    {"version_id", foreign_key}
    {"arch", varchar}
    {"downloads", integer}

    {"rock_key", varchar}
    {"rock_fname", varchar}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "rocks", "version_id", "arch", unique: true
  create_index "rocks", "rock_key", unique: true
  create_index "rocks", "rock_fname"

  --
  -- Depedencies
  --
  create_table "dependencies", {
    {"module_id", foreign_key}
    {"dependency", varchar}
    {"full_dependency", varchar}

    "PRIMARY KEY (module_id, dependency)"
  }

  --
  -- Manifests
  --
  create_table "manifests", {
    {"id", serial}
    {"name", varchar}
    {"is_open", boolean} -- anyone can put a rock in it

    "PRIMARY KEY (id)"
  }

  create_index "manifests", "name", unique: true

  --
  -- ManifestAdmins
  --
  create_table "manifest_admins", {
    {"user_id", foreign_key}
    {"manifest_id", foreign_key}
    {"is_owner", boolean}

    "PRIMARY KEY (user_id, manifest_id)"
  }

  --
  -- ManifestModules
  --
  create_table "manifest_modules", {
    {"manifest_id", foreign_key}
    {"module_id", foreign_key}
    {"module_name", varchar}

    "PRIMARY KEY (manifest_id, module_id)"
  }

  create_index "manifest_modules", "manifest_id", "module_name", unique: true
  create_index "manifest_modules", "module_id"

destroy_schema = ->
  tbls = {
    "users", "modules", "versions", "rocks", "dependencies", "manifests",
    "manifest_modules"
  }

  for t in *tbls
    drop_table t


if ... == "test"
  db.query = print
  make_schema!

{ :make_schema, :destroy_schema }


