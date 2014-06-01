
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

  get_versions: =>
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

  -- copies module/versions/rocks to user
  copy_to_user: (user) =>
    return if user.id == @user_id

    bucket = require "storage_bucket"
    import Versions, Rocks, LinkedModules from require "models"

    module_keys = {
      "name", "display_name", "downloads", "summary", "description", "license",
      "homepage"
    }

    version_keys = {
      "version_name", "display_version_name", "rockspec_fname", "downloads",
      "rockspec_downloads", "lua_version", "source_url"
    }

    rock_keys = {
      "arch", "downloads", "rock_fname"
    }

    new_module = Modules\find user_id: user.id, name: @name
    unless new_module
      params = { k, @[k] for k in *module_keys }
      params.user_id = user.id
      params.current_version_id = -1
      new_module = Model.create Modules, params

    versions = @get_versions!
    for version in *versions
      new_version = Versions\find {
        module_id: new_module.id
        version_name: version.version_name
      }

      unless new_version
        params = { k, version[k] for k in *version_keys }
        params.module_id = new_module.id
        params.rockspec_key = "#{user.id}/#{version.rockspec_fname}"

        rockspec_text = bucket\get_file version.rockspec_key
        bucket\put_file_string rockspec_text, {
          key: params.rockspec_key
          mimetype: "text/x-rockspec"
        }

        new_version = Model.create Versions, params

      rocks = version\get_rocks!
      for rock in *rocks
        new_rock = Rocks\find {
          version_id: new_version.id
          arch: rock.arch
        }

        unless new_rock
          params = { k, rock[k] for k in *rock_keys }
          params.version_id = new_version.id
          params.rock_key = "#{user.id}/#{rock.rock_fname}"

          rock_bin = bucket\get_file rock.rock_key
          bucket\put_file_string rock_bin, {
            key: params.rock_key
            mimetype: "application/x-rock"
          }

          new_rock = Model.create Rocks, params

    LinkedModules\find_or_create @id, user.id
    new_module

