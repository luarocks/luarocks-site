import request from require "lapis.spec.server"

-- returns headers for logged in user
log_in_user = (user) ->
  config = require("lapis.config").get "test"
  import encode_session from require "lapis.session"
  import escape from require "lapis.util"

  stub = { session: {} }

  user\write_session stub
  val = escape encode_session stub.session

  {
    "Cookie": "#{config.session_name}=#{val}; Path=/"
  }

-- make a request as logged in as a user
request_as = (user, url, opts={}) ->
  opts.headers or= {}

  if user
    for k, v in pairs log_in_user user
      opts.headers[k] = v

  if opts.post and opts.post.csrf_token == nil
    import generate_token from require "lapis.csrf"
    opts.post.csrf_token = generate_token nil, user.id

  request url, opts


{ :log_in_user, :request_as }
