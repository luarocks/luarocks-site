
import Model from require "lapis.db.model"
import get_all_pages from require "helpers.models"

class Manifests extends Model
  @create: (name, is_open=false) =>
    if @check_unique_constraint "name", name
      return nil, "Manifest name already taken"

    Model.create @, { :name, :is_open }

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
    if type(...) == "table"
      opts = ...

      if opts.prepare_results
        prepare_results = opts.prepare_results
        opts.prepare_results = nil

      if opts.per_page
        per_page = opts.per_page
        opts.per_page = nil

    ManifestModules\paginated "where manifest_id = ?", @id, {
      :per_page
      prepare_results: (manifest_modules) ->
        Modules\include_in manifest_modules, "module_id", unpack args
        modules = [mm.module for mm in *manifest_modules]
        modules = prepare_results modules if prepare_results
        modules
    }

  source_url: (r) => r\build_url!

  url_key: (name) =>
    if name == "manifest"
      @name
    else
      @id
