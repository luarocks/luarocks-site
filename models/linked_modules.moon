
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE linked_modules (
--   module_id integer NOT NULL,
--   user_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY linked_modules
--   ADD CONSTRAINT linked_modules_pkey PRIMARY KEY (module_id, user_id);
--
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

