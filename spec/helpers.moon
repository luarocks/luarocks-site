import request from require "lapis.spec.server"
import generate_token from require "lapis.csrf"

add_cookie = (headers, name, val) ->
  import escape from require "lapis.util"
  assign = "#{escape name}=#{escape val}"

  if old = headers.Cookie
    headers.Cookie = "#{old}; #{assign}"
  else
    headers.Cookie = assign

_request = (url, opts, ...) ->
  if opts and opts.csrf
    opts.post or= {}

    r = { cookies: {} }

    token_param = type(opts.csrf) == "string" and opts.csrf or "csrf_token"
    opts.post[token_param] = generate_token r

    opts.headers or= {}
    config = require("lapis.config").get "test"

    add_cookie(
      opts.headers
      assert next(r.cookies), "missing csrf cookie"
      r.cookies[next(r.cookies)]
    )

    opts.csrf = nil

  out = { request url, opts, ... }
  opts or= {}

  busted = require "busted"
  busted.publish {"lapis", "request"}, url, opts, ...

  if out[1] == 200 and not opts.post and out[3].content_type == "text/html"
    busted.publish {"lapis", "screenshot"}, url, opts, ...

  unpack out

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
    opts.csrf or= true

  _request url, opts

do_upload_as = (user, url, param_name, filename, file_content, opts) ->
  import generate_token from require "lapis.csrf"

  unless pcall -> require "moonrocks.multipart"
    error "Need moonrocks to run upload spec"
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

should_load = (url, expected_status=200) ->
  assert = require "luassert"
  import it from require "busted"

  it "should load #{url} with #{expected_status}", ->
    assert.same expected_status, (request url)

{ :log_in_user, :request_as, request: _request, :do_upload_as, :should_load }
