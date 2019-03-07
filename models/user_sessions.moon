
db = require "lapis.db"
import Model, enum from require "lapis.db.model"
date = require "date"

class UserSessions extends Model
  @timestamp: true

  @types: enum {
    login_password: 1
    register: 2
    update_password: 3
    admin: 4
    login_github: 5
    register_github: 6
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


