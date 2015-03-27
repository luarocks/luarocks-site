
db = require "lapis.db"
bucket = require "storage_bucket"

import Model from require "lapis.db.model"
import increment_counter, safe_insert from require "helpers.models"

class Rocks extends Model
  @timestamp: true

  @create: (version, arch, rock_key) =>
    safe_insert @, {
      version_id: version.id
      rock_fname: rock_key\match "/([^/]*)$"
      :arch, :rock_key
    }, {version_id: version.id, :arch }

  url: => bucket\file_url @rock_key .. "?#{@revision}"

  increment_download: =>
    import Versions from require "models"

    increment_counter @, "downloads"
    version = @version or Versions\find id: @version_id
    version\increment_download {"downloads"}

  delete: =>
    if super!
      bucket\delete_file @rock_key
      true

  increment_revision: =>
    @update revision: db.raw "revision + 1"

