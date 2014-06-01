
import Model from require "lapis.db.model"

class LinkedModules extends Model
  @primary_key: {"module_id", "user_id"}
  @timestamp: true

  @find_or_create: (module_id, user_id) =>
    data = { :module_id, :user_id }
    link = @find data

    unless link
      link = @create data

  -- update the copyed module
  update_user: =>
    import Users, Modules from require "models"
    user = Users\find @user_id
    mod = Modules\find @module_id
    mod\copy_to_user user

