import Model from require "lapis.db.model"

class UserServerLogs extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }
