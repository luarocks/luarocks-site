import request from require "lapis.spec.server"

take_screenshots = os.getenv "SCREENSHOT"

local *

_request = (...) ->
  if take_screenshots
    request_with_snap ...
  else
    request ...

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

  _request url, opts

request_with_snap = do
  dir = "spec/screenshots"
  counter = 1
  (url, opts, ...) ->
    out = { request url, opts, ... }

    opts or= {}
    if out[1] == 200 and not opts.post
      if counter == 1
        os.execute "rm #{dir}/*.png"

      import get_current_server from require "lapis.spec.server"
      server = get_current_server!

      host, path = url\match "^https?://([^/]*)(.*)$"
      unless host
        host = "127.0.0.1"
        path = url

      full_url = "http://#{host}:#{server.app_port}#{path}"
      headers = for k,v in pairs opts.headers or {}
        "'--header=#{k}:#{v}'"

      headers = table.concat headers

      cmd = "CutyCapt #{headers} '--url=#{full_url}' '--out=#{dir}/#{counter}.png'"
      assert os.execute cmd

      counter += 1

    unpack out

do_upload_as = (user, url, param_name, filename, file_content, opts) ->
  import generate_token from require "lapis.csrf"

  unless pcall -> require "moonrocks.multipart"
    pending "Need moonrocks to run upload spec"
    return false

  import File, encode from require "moonrocks.multipart"

  f = with File filename, "application/octet-stream"
    .content = -> file_content

  data, boundary = encode {
    csrf_token: user and generate_token nil, user.id
    [param_name]: f
  }

  req_opts = {
    method: "POST"
    headers: {
      "Content-type": "multipart/form-data; boundary=#{boundary}"
    }

    :data
  }

  if opts
    for k, v in pairs opts
      req_opts[k] = v

  request_as user, url, req_opts


{ :log_in_user, :request_as, request: _request, :do_upload_as }
