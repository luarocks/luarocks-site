db = require "lapis.db"
import Model from require "lapis.db.model"

class GithubAccounts extends Model
  @primary_key: {"user_id", "github_user_id"}
  @timestamp: true
