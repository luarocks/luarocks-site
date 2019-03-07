
db = require "lapis.db"
schema = require "lapis.db.schema"

import
  create_table
  add_column
  create_index
  drop_index
  drop_column
  drop_table
  from schema

import
  serial
  varchar
  text
  time
  integer
  foreign_key
  boolean
  enum
  from schema.types

{
  -- migrate user slugs
  [1370275336]: =>
    -- updates from legacy slugify that didn't lowercase
    -- slugify = (str) -> (str\gsub("%s+", "-")\gsub("[^%w%-_]+", ""))

    util = require "lapis.util"
    import Users from require "models"
    for u in *Users\select!
      new_slug = util.slugify u.username
      continue if new_slug == u.slug
      u\update {
        slug: new_slug
      }

  -- add display name to modules, convert names to lowercase
  -- add display name to versions, convert names to lowercase
  -- make rock filenames/ach lowercase
  [1370277180]: =>
    import Modules, Versions, Rocks from require "models"

    add_column "modules", "display_name", varchar null: true
    for m in *Modules\select!
      new_name = m.name\lower!
      m\update {
        display_name: if new_name != m.name then m.name
        name: new_name
      }

    add_column "versions", "display_version_name", varchar null: true
    for v in *Versions\select!
      new_name = v.version_name\lower!
      v\update {
        display_version_name: if new_name != v.version_name then v.version_name
        version_name: new_name
        rockspec_fname: v.rockspec_fname\lower!
      }

    for r in *Rocks\select!
      r\update {
        rock_fname: r.rock_fname\lower!
        arch: r.arch\lower!
      }

  [1393557726]: =>
    add_column "versions", "lua_version", varchar null: true

  [1401338238]: =>
    add_column "versions", "development", boolean

  [1401600469]: =>
    add_column "versions", "source_url", text null: true

  [1401727722]: =>
    add_column "manifests", "display_name", varchar null: true
    add_column "manifests", "description", text null: true

    -- add timestamps
    add_column "manifests", "created_at", time default: db.raw("now()")
    add_column "manifests", "updated_at", time default: db.raw("now()")

    add_column "manifest_admins", "created_at", time default: db.raw("now()")
    add_column "manifest_admins", "updated_at", time default: db.raw("now()")

    db.query "alter table manifests alter column created_at drop default"
    db.query "alter table manifests alter column updated_at drop default"

    db.query "alter table manifest_admins alter column created_at drop default"
    db.query "alter table manifest_admins alter column updated_at drop default"

  [1401810343]: =>
    add_column "manifests", "modules_count", integer
    add_column "manifests", "versions_count", integer

    db.query [[
      update manifests set
        modules_count = (select count(*) from manifest_modules where manifest_id = manifests.id),
        versions_count = (select count(*) from versions where versions.module_id in (select module_id from manifest_modules where manifest_id = manifests.id)),
        updated_at = ?
    ]], db.format_date!


  [1408086639]: =>
    create_index "users", db.raw("lower(email)"), unique: true
    create_index "users", db.raw("lower(username)"), unique: true

    drop_index "users", "email"
    drop_index "users", "username"


  [1413268904]: =>
    add_column "modules", "endorsements_count", integer

  [1423334387]: =>
    add_column "modules", "has_dev_version", boolean
    db.query [[
      update modules set has_dev_version = exists(
        select 1 from versions where module_id = modules.id
        and development
      )
    ]]

  [1427443263]: =>
    import Modules from require "models"
    db.query "create extension pg_trgm;"
    db.query "create index modules_name_search_idx on modules using gin(#{Modules.name_search_index} gin_trgm_ops)"

  [1427444511]: =>
    db.query "create index users_username_idx on users using gin(username gin_trgm_ops)"


  [1427445542]: =>
    add_column "versions", "revision", integer default: 1
    add_column "rocks", "revision", integer default: 1

  [1427448938]: =>
    drop_table "dependencies"
    create_table "dependencies", {
      {"version_id", foreign_key}
      {"dependency_name", varchar}
      {"dependency", varchar}

      "PRIMARY KEY (version_id, dependency_name)"
    }

  [1437970205]: =>
    create_index "dependencies", "dependency_name"

  [1438259102]: =>
    create_table "followings", {
      {"source_user_id", foreign_key}
      {"object_type", enum}
      {"object_id", foreign_key}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (source_user_id, object_type, object_id)"
    }

    create_index "followings", "object_type", "object_id"

    add_column "users", "following_count", integer
    add_column "modules", "followers_count", integer

  [1438314813]: =>
    add_column "versions", "external_rockspec_url", text null: true

  [1438999272]: =>
    create_table "notifications", {
      {"id", serial}
      {"user_id", foreign_key}

      {"type", integer}

      {"object_type", enum}
      {"object_id", foreign_key}

      {"count", integer}

      {"seen", boolean}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "notifications", "user_id", "seen", "id"
    create_index "notifications", "user_id", "type", "object_type", "object_id", where: "not seen", unique: "true"

    create_table "notification_objects", {
      {"notification_id", foreign_key}

      {"object_type", enum}
      {"object_id", foreign_key}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (notification_id, object_type, object_id)"
    }

  [1439449229]: =>
    drop_column "user_data", "data"
    add_column "user_data", "twitter", text null: true
    add_column "user_data", "website", text null: true
    add_column "user_data", "profile", text null: true

  [1439949273]: =>
    add_column "user_data", "github", text null: true
    db.query "update user_data set github = (
      select github_login from github_accounts where github_accounts.user_id = user_data.user_id
      limit 1
    )"

  [1443373251]: =>
    add_column "users", "modules_count", integer
    db.update "users", {
      modules_count: db.raw "(select count(*) from modules where user_id = users.id)"
    }

  [1443382411]: =>
    add_column "users", "last_active_at", time null: true

  [1453406400]: =>
    add_column "versions", "archived", boolean default: false

  [1462567085]: =>
    create_table "approved_labels", {
      {"id", serial}
      {"name", varchar}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "approved_labels", "name"

    add_column "modules", "labels", text array: true, null: true
    db.query "create index on modules using gin(labels) where modules is not null"

  [1475034338]: =>
    drop_index "approved_labels", "name"
    create_index "approved_labels", "name", unique: true

  [1475269875]: =>
    drop_column "modules", "endorsements_count"

  [1476481149]: =>
    add_column "api_keys", "comment", text null: true

  [1496539644]: =>
    add_column "users", "followers_count", integer

  [1499055289]: =>
    db.query "alter table users alter column encrypted_password drop not null"

  [1499794884]: =>
    db.query [[create extension if not exists "uuid-ossp"]]

  [1500093078]: =>
    add_column "users", "display_name", varchar null: true

  [1500307302]: =>
    add_column "followings", "type", enum default: 1

  [1500308531]: =>
    add_column "users", "stared_count", integer default: 0
    add_column "modules", "stars_count", integer default: 0

  [1500318771]: =>
    db.query "alter table followings drop constraint followings_pkey"
    db.query "alter table followings add primary key(source_user_id, object_type, object_id, type)"

  [1551765161]: =>
    db.query "update user_data set password_reset_token = null"

  [1551905631]: =>
    create_table "user_server_logs", {
      {"id", serial}
      {"user_id", foreign_key null: true}

      {"created_at", time}
      {"updated_at", time}

      {"log_date", time}
      {"log", text}
      {"data", "json"}

      "PRIMARY KEY (id)"
    }

    create_index "user_server_logs", "user_id", "log_date"

  [1551918146]: =>
    add_column "api_keys", "revoked", boolean default: false
    add_column "api_keys", "revoked_at", time null: true
    add_column "api_keys", "last_used_at", time null: true

  [1551935898]: =>
    create_table "user_sessions", {
      {"id", serial}
      {"user_id", serial}
      {"type", enum}
      {"revoked", boolean default: false}

      {"ip", "inet not null"}
      {"accept_lang", text null: true}
      {"user_agent", text null: true}

      {"last_active_at", time null: true}
      {"revoked_at", time null: true}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "user_sessions", "user_id"

  [1551990095]: =>
    create_table "user_activity_logs", {
      {"id", serial}
      {"user_id", foreign_key}

      {"source", enum}
      {"action", text}
      {"data", "json"}

      {"ip", "inet"}
      {"accept_lang", text null: true}
      {"user_agent", text null: true}

      {"created_at", time}
      {"updated_at", time}

      {"object_type", enum null: true}
      {"object_id", foreign_key null: true}

      "PRIMARY KEY (id)"
    }

    create_index "user_activity_logs", "user_id", "created_at"

}


