
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_data (
--   user_id integer NOT NULL,
--   email_verified boolean DEFAULT false NOT NULL,
--   password_reset_token character varying(255),
--   data text NOT NULL
-- );
-- ALTER TABLE ONLY user_data
--   ADD CONSTRAINT user_data_pkey PRIMARY KEY (user_id);
--
class UserData extends Model
  @primary_key: "user_id"

  @create: (user_id) =>
    Model.create @, {
      :user_id
      data: "{}"
    }
