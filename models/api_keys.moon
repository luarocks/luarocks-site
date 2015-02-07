
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"

class ApiKeys extends Model
  @primary_key: {"user_id", "key"}
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @generate: (user_id, source) =>
    key = generate_key 40
    @create { :user_id, :key, :source }

  url_key: => @key
