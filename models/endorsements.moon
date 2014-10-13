

import Model from require "lapis.db.model"

class Endorsements extends Model
  @primary_key: {"user_id", "module_id"}
  @timestamp: true
