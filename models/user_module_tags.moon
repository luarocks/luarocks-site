
import slugify from require "lapis.util"
import Model from require "lapis.db.model"

class UserModuleTags extends Model
  @primary_key: {"user_id", "module_id", "tag"}
  @timestamp: true

  create: (t) =>
    assert t.user_id, "need user id"
    assert t.module_id, "need module id"
    t.tag = slugify assert t.tag, "need tag"
    Model.create @, t

