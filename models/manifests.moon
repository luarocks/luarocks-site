
import Model from require "lapis.db.model"
import get_all_pages from require "helpers.models"

class Manifests extends Model
  @create: (name, is_open=false) =>
    if @check_unique_constraint "name", name
      return nil, "Manifest name already taken"

    Model.create @, { :name, :is_open }

  @root: =>
    assert Manifests\find(name: "root"), "Missing root manifest"

  allowed_to_add: (user) =>
    return false unless user
    return true if @is_open or user\is_admin!

    import ManifestAdmins from require "models"
    ManifestAdmins\find user_id: user.id, manifest_id: @id

  all_modules: (...) =>
    import ManifestModules, Modules from require "models"
    args = {...}

    pager = ManifestModules\paginated "where manifest_id = ?", @id, {
      per_page: 50
      prepare_results: (manifest_modules) ->
        Modules\include_in manifest_modules, "module_id", unpack args
        [mm.module for mm in *manifest_modules]
    }

    modules = get_all_pages pager
    table.sort modules, (a,b) ->
      a.name < b.name

    modules

  source_url: (r) => r\build_url!

  url_key: (name) =>
    if name == "manifest"
      @name
    else
      @id
