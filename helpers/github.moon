
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
      scope: "user:email"
      :state
    }

    "#{@login_prefix}/login/oauth/authorize?#{params}"

  _client_auth: =>
    "Basic #{ngx.encode_base64 "#{@client_id}:#{@client_secret}"}"

  access_token: (code) =>
    params = encode_query_string {
      :code
    }

    res, status = http.simple {
      url: "#{@login_prefix}/login/oauth/access_token?#{params}"
      method: "POST"

      headers: {
        "User-agent": "luarocks.org"
        "Authorization": @_client_auth!
      }
    }

    if status != 200
      return nil, "unexpected status from github #{status}"

    out = parse_query_string res

    if out.error
      return nil, out.error

    out

  delete_access_token: (access_token) =>
    @_api_request "DELETE", "/applications/#{@client_id}/tokens/#{access_token}", {}, {
      "Authorization": @_client_auth!
    }

  -- for requests to api prefix
  _api_request: (method="GET", url, params={}, more_headers=nil) =>
    if next params
      params = encode_query_string params
      url = "#{url}?#{params}"

    headers = {
      "User-agent": "luarocks.org"
    }

    if more_headers
      for k,v in pairs more_headers
        headers[k] = v

    req = {
      :method
      url: "#{@api_prefix}#{url}"
      :headers
    }

    res, status = http.simple req

    if status != 200
      return nil, "unexpected status from github #{status} - #{res}"

    json.decode res

  primary_email: (access_token) =>
    emails = assert @_api_request "GET", "/user/emails", nil, {
      "Authorization": "token #{access_token}"
    }

    for email in *emails
      if email.primary
        return email.email

    nil

  user: (access_token) =>
    @_api_request "GET", "/user", nil, {
      "Authorization": "token #{access_token}"
    }

  orgs: (user, access_token) =>
    @_api_request "GET", "/users/#{user}/orgs", nil, {
      "Authorization": "token #{access_token}"
    }

config = require("lapis.config").get!
GitHub config.github_client_id, config.github_client_secret
