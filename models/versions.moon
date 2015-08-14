
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

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE versions (
--   id integer NOT NULL,
--   module_id integer NOT NULL,
--   version_name character varying(255) NOT NULL,
--   rockspec_key character varying(255) NOT NULL,
--   rockspec_fname character varying(255) NOT NULL,
--   downloads integer DEFAULT 0 NOT NULL,
--   rockspec_downloads integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   display_version_name character varying(255),
--   lua_version character varying(255),
--   development boolean DEFAULT false NOT NULL,
--   source_url text,
--   revision integer DEFAULT 1 NOT NULL,
--   external_rockspec_url text
-- );
-- ALTER TABLE ONLY versions
--   ADD CONSTRAINT versions_pkey PRIMARY KEY (id);
-- CREATE INDEX versions_downloads_idx ON versions USING btree (downloads);
-- CREATE UNIQUE INDEX versions_module_id_version_name_idx ON versions USING btree (module_id, version_name);
-- CREATE INDEX versions_rockspec_fname_idx ON versions USING btree (rockspec_fname);
-- CREATE UNIQUE INDEX versions_rockspec_key_idx ON versions USING btree (rockspec_key);
--
class Versions extends Model
  @timestamp: true

  @relations: {
    {"module", belongs_to: "Modules"}
    {"dependencies", has_many: "Dependencies"}
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

    version\update_dependencies spec
    version

  update_from_spec: (spec) =>
    lua_version = get_lua_version spec

    if lua_version != @lua_version
      @update lua_version: lua_version or db.NULL

    @update_dependencies spec

  url_key: (name) => @version_name

  url_params: =>
    mod = @get_module!
    "module_version", {
      module: mod
      user: mod\get_user!
      version: @version_name
    }

  url: =>
    if @external_rockspec_url
      @external_rockspec_url, true
    else
      bucket\file_url @rockspec_key .. "?#{@revision}"

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

  update_dependencies: (spec) =>
    import Dependencies from require "models"
    spec or= @get_spec!
    return nil, "invalid spec" unless spec

    db.delete "dependencies", {
      version_id: @id
    }

    import trim from require "lapis.util"

    return unless type(spec.dependencies) == "table"

    seen = {}
    tuples = for d in *spec.dependencies
      d = trim d
      name = d\match("[^%s]+") or d
      continue if seen[name]
      seen[name] = true
      db.interpolate_query "(?, ?, ?)", @id, name, d

    return unless next tuples

    tbl = db.escape_identifier Dependencies\table_name!
    db.query "
      insert into #{tbl} (version_id, dependency_name, dependency)
      values #{table.concat tuples, ", "}
    "
    true

  increment_revision: =>
    @update revision: db.raw "revision + 1"

  allowed_to_edit: (user) =>
    return false unless user
    @get_module!\allowed_to_edit user

