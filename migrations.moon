
db = require "lapis.db"
schema = require "lapis.db.schema"

import
  create_table
  add_column
  create_index
  drop_index
  drop_column
  from schema


import
  serial
  varchar
  text
  time
  integer
  foreign_key
  boolean
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


}
