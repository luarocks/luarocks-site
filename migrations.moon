
db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, add_index, drop_column from schema

{ :varchar } = schema.types

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

}
