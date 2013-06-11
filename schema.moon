
db = require "lapis.nginx.postgres"
schema = require "lapis.db.schema"
migrations = require "lapis.db.migrations"

import create_table, create_index, drop_table from schema

make_schema = ->
  {
    :serial
    :varchar
    :text
    :time
    :integer
    :foreign_key
    :boolean
  } = schema.types

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

  create_table "user_data", {
    {"user_id", foreign_key}
    {"email_verified", boolean}
    {"password_reset_token", varchar null: true}
    {"data", text}
    "PRIMARY KEY (user_id)"
  }

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
    {"display_name", varchar null: true}

    {"downloads", integer}
    {"current_version_id", foreign_key}

    {"summary", varchar null: true}
    {"description", text null: true}

    {"license", varchar null: true}
    {"homepage", varchar null: true}

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
    {"display_version_name", varchar null: true}

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
  create_index "versions", "rockspec_key", unique: true -- TODO: delete index
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
  create_index "rocks", "rock_key", unique: true -- TODO: delete this index
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

  migrations.create_migrations_table!


  --
  -- ApiKeys
  --
  create_table "api_keys", {
    {"user_id", foreign_key}
    {"key", varchar}

    {"source", varchar null: true}
    {"actions", integer}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (key)"
  }

  create_index "api_keys", "user_id"

destroy_schema = ->
  tbls = {
    "users", "modules", "versions", "rocks", "dependencies", "manifests",
    "manifest_modules", "api_keys"
  }

  for t in *tbls
    drop_table t

if ... == "test"
  db.query = print
  db.select = -> { { c: 0 } }
  make_schema!

{ :make_schema, :destroy_schema }


