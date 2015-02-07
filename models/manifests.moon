
import Model from require "lapis.db.model"
import get_all_pages from require "helpers.models"

db = require "lapis.db"

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

  find_modules: (opts={}) =>
    import ManifestModules, Modules from require "models"

    dev_only = opts.dev_only
    opts.dev_only = nil

    fields = opts.fields
    opts.fields = nil

    module_prepare_results = opts.prepare_results

    opts.prepare_results = (manifest_modules) ->
      Modules\include_in manifest_modules, "module_id", fields: fields
      modules = [mm.module for mm in *manifest_modules]
      modules = module_prepare_results modules if module_prepare_results
      modules

    clause = if dev_only
      -- TODO: this query can be better
      db.interpolate_query [[
        inner join modules on manifest_modules.module_id = modules.id
        where manifest_id = ? and has_dev_version
        order by module_name asc
      ]], @id
    else
      db.interpolate_query [[
        where manifest_id = ?
        order by module_name asc
      ]], @id

    ManifestModules\paginated clause, opts

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

  update_counts: =>
    @update {
      modules_count: db.raw "(select count(*) from manifest_modules where manifest_id = manifests.id)"
      versions_count: db.raw "(select count(*) from versions where versions.module_id in (select module_id from manifest_modules where manifest_id = manifests.id))"
    }

  -- purge any caches for this manifest
  -- updates the counts, and the updated_at field of manifest
  purge: =>
    @update_counts!

    return unless ngx and ngx.shared
    for path in *{"/manifest", "/manifest-5.1", "/manifest-5.2"}
      ngx.shared.manifest_cache\set path, nil

  has_module: (mod) =>
    import ManifestModules from require "models"
    ManifestModules\find manifest_id: @id, module_id: mod.id

  is_root: =>
    @name == "root"

  name_for_display: =>
    @display_name or @name

