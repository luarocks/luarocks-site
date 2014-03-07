
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


{ :log_in_user }
