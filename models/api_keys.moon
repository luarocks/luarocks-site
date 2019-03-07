
db = require "lapis.db"
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"

date = require "date"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE api_keys (
--   user_id integer NOT NULL,
--   key character varying(255) NOT NULL,
--   source character varying(255),
--   actions integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   comment text
-- );
-- ALTER TABLE ONLY api_keys
--   ADD CONSTRAINT api_keys_pkey PRIMARY KEY (key);
-- CREATE INDEX api_keys_user_id_idx ON api_keys USING btree (user_id);
--
class ApiKeys extends Model
  @primary_key: {"user_id", "key"}
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @generate: (user_id, source) =>
    key = generate_key 40
    @create { :user_id, :key, :source }

  update_last_used_at: =>
    span = if @last_active_at
      date.diff(date(true), date(@last_active_at))\spanminutes!

    if not span or span > 15
      @update {
        last_used_at: db.raw"date_trunc('second', now() at time zone 'utc')"
      }, timestamp: false

  increment_actions: (amount=1) =>
    @update { actions: db.raw "actions + 1" }, timestamp: false

  url_key: => @key

  revoke: =>
    @update {
      revoked: true
      revoked_at: db.raw "date_trunc('second', now() at time zone 'utc')"
    }

