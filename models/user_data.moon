
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_data (
--   user_id integer NOT NULL,
--   email_verified boolean DEFAULT false NOT NULL,
--   password_reset_token character varying(255),
--   twitter text,
--   website text,
--   profile text,
--   github text
-- );
-- ALTER TABLE ONLY user_data
--   ADD CONSTRAINT user_data_pkey PRIMARY KEY (user_id);
-- ALTER TABLE ONLY user_data
--   ADD CONSTRAINT user_data_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
--
class UserData extends Model
  @primary_key: "user_id"

  @create: (user_id) =>
    super { :user_id }

  github_handle: =>
    return unless @github
    github = @github\match("github.com/([^/]+)") or @github
    github\match "^([a-zA-Z0-9_-]+)$"

  -- without @
  twitter_handle: =>
    return unless @twitter
    @twitter\match("twitter.com/([^/]+)") or @twitter\match("^@(.+)") or @twitter


