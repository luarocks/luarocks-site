
bucket = require "storage_bucket"
db = require "lapis.db"

import Model from require "lapis.db.model"
import increment_counter from require "helpers.models"

get_lua_version = (spec) ->
  return unless spec.dependencies
  for dep in *spec.dependencies
    if dep\match "^lua%s"
      return dep

  nil

-- a rockspec
class Versions extends Model
  @timestamp: true

  @relations: {
    {"module", belongs_to: "Modules"}
  }

  @sort_versions: (versions) =>
    import parse_version from require "ext.luarocks.deps"

    for v in *versions
      v._parsed_version_name = parse_version v.version_name

    table.sort versions, (a, b) ->
      a._parsed_version_name > b._parsed_version_name

    versions

  @version_name_is_development: do
    patterns = {
      "^scm%-"
      "^cvs%-"
      "^svn%-"
      "^git%-"
      "^dev%-"
    }

    (version_name) =>
      version_name = version_name\lower!
      for p in *patterns
        return true if version_name\match p
      false

  @create: (mod, spec, rockspec_key) =>
    version_name = spec.version\lower!

    if @check_unique_constraint module_id: mod.id, version_name: version_name
      return nil, "This version is already uploaded"

    version = Model.create @, {
      module_id: mod.id
      display_version_name: if version_name != spec.version then spec.version
      rockspec_fname: rockspec_key\match "/([^/]*)$"
      lua_version: get_lua_version spec
      development: @version_name_is_development version_name
      source_url: spec.source and spec.source.url

      :rockspec_key, :version_name
    }

    if version.development
      mod = version\get_module!
      mod\update has_dev_version: true unless mod.has_dev_version

    version

  update_from_spec: (spec) =>
    lua_version = get_lua_version spec
    if lua_version != @lua_version
      @update lua_version: lua_version or db.NULL

  url_key: (name) => @version_name

  url: => bucket\file_url @rockspec_key .. "?#{@revision}"

  name_for_display: =>
    @display_version_name or @version_name

  increment_download: (counters={"downloads", "rockspec_downloads"}) =>
    import Modules, DownloadsDaily from require "models"

    increment_counter @, counters
    increment_counter Modules\load(id: @module_id), "downloads"
    DownloadsDaily\increment @id

  get_rocks: =>
    unless @_rocks
      import Rocks from require "models"
      @_rocks = Rocks\select "where version_id = ?", @id

    @_rocks

  delete: =>
    if super!
      -- delete rockspec
      bucket\delete_file @rockspec_key

      if mod = @get_module!
        mod\update_has_dev_version!

      -- remove rocks
      import Rocks from require "models"
      rocks = Rocks\select "where version_id = ?", @id
      for r in *rocks
        r\delete!

      true

  get_spec: =>
    http = if ngx
      require "lapis.nginx.http"
    else
      require "socket.http"

    url = @url!
    body, status = http.request url

    if status != 200
      return nil, "failed to download rockspec, status: #{status}"

    import parse_rockspec from require "helpers.uploaders"
    parse_rockspec body

  increment_revision: =>
    @update revision: db.raw "revision + 1"

