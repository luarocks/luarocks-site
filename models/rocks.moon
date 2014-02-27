
bucket = require "storage_bucket"

import Model from require "lapis.db.model"
import increment_counter from require "helpers.models"

class Rocks extends Model
  @timestamp: true

  @create: (version, arch, rock_key) =>
    if @check_unique_constraint { version_id: version.id, :arch }
      return nil, "Rock already exists"

    Model.create @, {
      version_id: version.id
      rock_fname: rock_key\match "/([^/]*)$"
      :arch, :rock_key
    }

  url: => bucket\file_url @rock_key

  increment_download: =>
    import Versions from require "models"

    increment_counter @, "downloads"
    version = @version or Versions\find id: @version_id
    version\increment_download {"downloads"}

  delete: =>
    super!
    bucket\delete_file @rock_key
