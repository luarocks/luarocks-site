
import Model from require "lapis.db.model"
import get_all_pages from require "helpers.models"

class Manifests extends Model
  @timestamp: true

  @create: (name, is_open=false, description) =>
    import slugify from require "lapis.util"

    display_name = name
    name = slugify name

    if "" == name\gsub "[^%w]+", ""
      return nil, "invalid manifest name"

    display_name = nil if name == display_name

    if @check_unique_constraint "name", name
      return nil, "manifest name already taken"

    Model.create @, { :name, :is_open, :display_name, :description }

  @root: =>
    (assert Manifests\find(name: "root"), "Missing root manifest")

  allowed_to_add: (user) =>
    return false unless user
    return true if @is_open or user\is_admin!

    import ManifestAdmins from require "models"
    ManifestAdmins\find user_id: user.id, manifest_id: @id

  find_modules: (...) =>
    import ManifestModules, Modules from require "models"
    prepare_results, per_page = nil

    args = {...}
    if type(... or nil) == "table"
      opts = ...

      if opts.prepare_results
        prepare_results = opts.prepare_results
        opts.prepare_results = nil

      if opts.per_page
        per_page = opts.per_page
        opts.per_page = nil

    ManifestModules\paginated [[
      where manifest_id = ?
      order by module_name asc
    ]], @id, {
      :per_page
      prepare_results: (manifest_modules) ->
        Modules\include_in manifest_modules, "module_id", unpack args
        modules = [mm.module for mm in *manifest_modules]
        modules = prepare_results modules if prepare_results
        modules
    }

  source_url: (r) =>
    if @is_root!
      r\build_url!
    else
      r\build_url r\url_for "manifest", manifest: @name

  url_key: (name) =>
    if name == "manifest"
      @name
    else
      @id

  url_params: =>
    "manifest", manifest: @name

  -- purge any caches for this manifest
  -- only the root manifest is cached right now
  purge: =>
    return unless ngx and ngx.shared
    return unless @name == "root"

    for path in *{"/manifest", "/manifest-5.1", "/manifest-5.2"}
      ngx.shared.manifest_cache\set path, nil

  has_module: (mod) =>
    import ManifestModules from require "models"
    ManifestModules\find manifest_id: @id, module_id: mod.id

  is_root: =>
    @name == "root"

  name_for_display: =>
    @display_name or @name

