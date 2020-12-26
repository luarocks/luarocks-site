
db = require "lapis.db"
import Model, enum from require "lapis.db.model"
date = require "date"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_sessions (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   type smallint NOT NULL,
--   revoked boolean DEFAULT false NOT NULL,
--   ip inet NOT NULL,
--   accept_lang text,
--   user_agent text,
--   last_active_at timestamp without time zone,
--   revoked_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY user_sessions
--   ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);
-- CREATE INDEX user_sessions_user_id_idx ON user_sessions USING btree (user_id);
--
class UserSessions extends Model
  @timestamp: true

  @types: enum {
    login_password: 1
    register: 2
    update_password: 3
    admin: 4
    login_github: 5
    register_github: 6
    update_email: 7
  }

  @create_from_request: (req, user, more_params) =>
    al = ngx and ngx.var.http_accept_language
    ua = ngx and ngx.var.http_user_agent

    al = unpack al if type(al) == "table"
    ua = unpack ua if type(ua) == "table"

    opts = {
      user_id: user.id
      ip: require("helpers.remote_addr")!
      -- country_code: nil
      accept_lang: al and al\sub 1,100
      user_agent: ua and ua\sub 1,100
    }

    if more_params
      for k,v in pairs more_params
        opts[k] = v

    @create opts

  @create: (opts) =>
    opts.type = @types\for_db opts.type
    super opts

  revoke: =>
    @update {
      revoked: true
      revoked_at: db.raw "date_trunc('second', now() at time zone 'utc')"
    }

  update_last_active: =>
    span = if @last_active_at
      date.diff(date(true), date(@last_active_at))\spanminutes!

    if not span or span > 15
      @update {
        last_active_at: db.raw"date_trunc('second', now() at time zone 'utc')"
      }, timestamp: false


