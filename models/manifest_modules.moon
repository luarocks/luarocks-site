
db = require "lapis.db"
import Model from require "lapis.db.model"

class ManifestModules extends Model
  @primary_key: {"manifest_id", "module_id"}

  @create: (manifest, mod) =>
    if @check_unique_constraint manifest_id: manifest.id, module_name: mod.name
      return nil, "Manifest already has a module named `#{mod.name}`"

    res = Model.create @, {
      manifest_id: manifest.id
      module_id: mod.id
      module_name: mod.name
    }
    manifest\purge!
    res

  @remove: (manifest, mod) =>
    assert mod.id and manifest.id, "Missing module/manifest"

    res = db.delete @@table_name!, {
      manifest_id: manifest.id
      module_id: mod.id
    }
    manifest\purge!
    res

  delete: =>
    error "use ManifestModules\\purge"
