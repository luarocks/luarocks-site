
import Model from require "lapis.db.model"

class UserData extends Model
  @primary_key: "user_id"

  @create: (user_id) =>
    Model.create @, {
      :user_id
      data: "{}"
    }
