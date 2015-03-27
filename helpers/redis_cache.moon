config = require"lapis.config".get!
redis = if ngx then require "resty.redis"

redis_down = nil

connect_redis = ->
  return nil unless config.redis_host

  r = redis\new!
  ok, err = r\connect config.redis_host,
    config.redis_port
  if ok
    r
  else
    redis_down = ngx.time!
    ok, err

get_redis = ->
  return unless redis
  return if redis_down and redis_down + 60 > ngx.time!

  r = ngx.ctx.redis
  unless r
    import after_dispatch from require "lapis.nginx.context"

    r, err = connect_redis!

    if r
      ngx.ctx.redis = r
      after_dispatch ->
        r\set_keepalive!
        ngx.ctx.redis = nil

  r

redis_cache = (prefix) ->
  (req) ->
    r = get_redis!

    {
      get: (key) =>
        return unless r
        with out = r\get "#{prefix}:#{key}"
          return nil if out == ngx.null

      set: (key, content, expire) =>
        return unless r
        r_key = "#{prefix}:#{key}"
        r\setex r_key, expire, content

      delete: (...) =>
        return unless r
        r\del unpack ["#{prefix}:#{k}" for k in *{...}]
    }


{ :get_redis, :redis_cache }

