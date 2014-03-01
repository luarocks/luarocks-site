
db = require "lapis.db"
import Model from require "lapis.db.model"

import concat from table

class Modules extends Model
  @timestamp: true

  -- spec: parsed rockspec
  @create: (spec, user) =>
    description = spec.description or {}
    name = spec.package\lower!

    if @check_unique_constraint user_id: user.id, :name
      return nil, "Module already exists"

    Model.create @, {
      :name
      user_id: user.id
      display_name: if name != spec.package then spec.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }

  url_key: (name) => @name

  name_for_display: =>
    @display_name or @name

  format_homepage_url: =>
    return if not @homepage or @homepage == ""

    unless @homepage\match "%w+://"
      return "http://" .. @homepage

    @homepage

  allowed_to_edit: (user) =>
    user and (user.id == @user_id or user\is_admin!)

  all_manifests: =>
    import ManifestModules, Manifests from require "models"

    assocs = ManifestModules\select "where module_id = ?", @id
    manifest_ids = [db.escape_literal(a.manifest_id) for a in *assocs]

    if next manifest_ids
      Manifests\select "where id in (#{concat manifest_ids, ","}) order by name asc"
    else
      {}

  get_verions: =>
    unless @_versions
      import Versions from require "models"
      @_versions = Versions\select "where module_id = ?", @id

    @_versions

  count_versions: =>
    res = db.query "select count(*) as c from versions where module_id = ?", @id
    res[1].c

  delete: =>
    import Versions, ManifestModules from require "models"

    super!
    -- Remove module from manifests
    db.delete ManifestModules\table_name!, module_id: @id

    -- Remove versions
    versions = Versions\select "where module_id = ? ", @id
    for v in *versions
      v\delete!
