
import encode_query_string, parse_query_string from require "lapis.util"
http = require "lapis.nginx.http"

json = require "cjson"

class GitHub
  login_prefix: "https://github.com"
  api_prefix: "https://api.github.com"

  new: (@client_id, @client_secret) =>

  login_url: (state) =>
    params = encode_query_string {
      client_id: @client_id
      :state
    }

    "#{@login_prefix}/login/oauth/authorize?#{params}"

  access_token: (code) =>
    params = encode_query_string {
      client_id: @client_id
      client_secret: @client_secret
      :code
    }

    res, status = http.simple {
      url: "#{@login_prefix}/login/oauth/access_token?#{params}"
      method: "POST"
    }

    if status != 200
      return nil, "unexpected status from github #{status}"

    out = parse_query_string res

    if out.error
      return nil, out.error

    out

  -- for requests to api prefix
  _api_request: (url, params={}) =>
    params = encode_query_string params
    req = {
      url: "#{@api_prefix}#{url}?#{params}"
      headers: {
        "User-agent": "rocks.moonscript.org"
      }
    }

    res, status = http.simple req
    if status != 200
      return nil, "unexpected status from github #{status} - #{res}"

    cjson.decode res

  user: (access_token) =>
    @_api_request "/user", { :access_token }

config = require("lapis.config").get!
GitHub config.github_client_id, config.github_client_secret
