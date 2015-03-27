db = require "lapis.db"
import Model from require "lapis.db.model"

class Dependencies extends Model
  @primary_key: {"version_id", "dependency_name"}
