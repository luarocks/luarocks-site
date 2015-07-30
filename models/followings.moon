db = require "lapis.db"
import Model from require "lapis.db.model"

class Followings extends Model
  @primary_key: {"source_user_id", "object_type", "object_id"}
  @timestamp: true

  @relations: {
    {"source_user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
    }}
  }

  @create: (opts) =>
    opts.object_type = @@object_types\for_db opts.object_type
    Model.create @, opts

