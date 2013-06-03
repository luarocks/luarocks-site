
db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, add_index, drop_column from schema

-- { } = schema.types

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
}
