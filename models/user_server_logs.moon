import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_server_logs (
--   id integer NOT NULL,
--   user_id integer,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   log_date timestamp without time zone NOT NULL,
--   log text NOT NULL,
--   data json
-- );
-- ALTER TABLE ONLY user_server_logs
--   ADD CONSTRAINT user_server_logs_pkey PRIMARY KEY (id);
-- CREATE INDEX user_server_logs_user_id_log_date_idx ON user_server_logs USING btree (user_id, log_date);
-- ALTER TABLE ONLY user_server_logs
--   ADD CONSTRAINT user_server_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
--
class UserServerLogs extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }
