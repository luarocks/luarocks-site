
import Model, enum from require "lapis.db.model"
import to_json from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_activity_logs (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   source smallint NOT NULL,
--   action text NOT NULL,
--   data json,
--   ip inet,
--   accept_lang text,
--   user_agent text,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   object_type smallint,
--   object_id integer
-- );
-- ALTER TABLE ONLY user_activity_logs
--   ADD CONSTRAINT user_activity_logs_pkey PRIMARY KEY (id);
-- CREATE INDEX user_activity_logs_user_id_created_at_idx ON user_activity_logs USING btree (user_id, created_at);
-- ALTER TABLE ONLY user_activity_logs
--   ADD CONSTRAINT user_activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
--
class UserActivityLogs extends Model
  @timestamp: true

  @sources: enum {
    web: 1
    api: 2
  }

  @relations: {
    {"user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
      [2]: {"version", "Versions"}
    }}
  }

  @create_from_request: (req, params) =>
    al = ngx and ngx.var.http_accept_language
    ua = ngx and ngx.var.http_user_agent

    al = unpack al if type(al) == "table"
    ua = unpack ua if type(ua) == "table"

    opts = {
      ip: require("helpers.remote_addr")!
      -- country_code: nil
      accept_lang: al and al\sub 1,100
      user_agent: ua and ua\sub 1,100
    }

    if params
      for k,v in pairs params
        opts[k] = v

    @create opts

  @create: (opts={}) =>
    opts.source = @sources\for_db opts.source

    if opts.object_type
      opts.object_type = @object_types\for_db opts.object_type

    if type(opts.data) == "table"
      opts.data = to_json opts.data

    super opts

  summarize: =>
    switch @action
      when "account.update_profile"
        parts = {}
        for k, v in pairs @data
          if v.before and v.after
            table.insert parts, "updated #{k}"
          elseif v.before
            table.insert parts, "cleared #{k}"
          elseif v.after
            table.insert parts, "set #{k}"

        table.concat parts, ", "
      when "account.update_password_attempt"
        @data.reason
      when "account.create_api_key", "account.revoke_api_key"
        if @data.key
          @data.key\sub(1, 10) .. "…"





