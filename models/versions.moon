
bucket = require "storage_bucket"

import Model from require "lapis.db.model"
import increment_counter from require "helpers.models"

-- a rockspec
class Versions extends Model
  @timestamp: true

  @create: (mod, spec, rockspec_key) =>
    version_name = spec.version\lower!

    if @check_unique_constraint module_id: mod.id, version_name: version_name
      return nil, "This version is already uploaded"

    Model.create @, {
      module_id: mod.id
      display_version_name: if version_name != spec.version then spec.version
      rockspec_fname: rockspec_key\match "/([^/]*)$"

      :rockspec_key, :version_name
    }

  url_key: (name) => @version_name

  url: => bucket\file_url @rockspec_key

  name_for_display: =>
    @display_version_name or @version_name

  increment_download: (counters={"downloads", "rockspec_downloads"}) =>
    import Modules from require "models"

    increment_counter @, counters
    increment_counter Modules\load(id: @module_id), "downloads"

  delete: =>
    super!
    -- delete rockspec
    bucket\delete_file @rockspec_key

    -- remove rocks
    import Rocks from require "models"

    rocks = Rocks\select "where version_id = ?", @id
    for r in *rocks
      r\delete!
