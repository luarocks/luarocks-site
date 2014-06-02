
db = require "lapis.db"
import Model from require "lapis.db.model"

class ManifestAdmins extends Model
  @timestamp: true
  @primary_key: {"user_id", "manifest_id"}

  @create: (manifest, user, is_owner=false) =>
    Model.create @, {
      manifest_id: manifest.id
      user_id: user.id
      :is_owner
    }

  @remove: (manifest, user) =>
    assert user.id and manifest.id, "Missing user/manifest"
    db.delete @@table_name!, {
      manifest_id: manifest.id
      user_id: user.id
    }
