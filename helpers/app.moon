
csrf = require "lapis.csrf"
config = require("lapis.config").get!

import yield_error from require "lapis.application"
import build_url from require "lapis.util"
import assert_valid from require "lapis.validate"

generate_csrf = => csrf.generate_token @
assert_csrf = => csrf.assert_token @

-- decorator for action functions to assert that function is called with CSRF
-- token validated
with_csrf = (fn) ->
  import assert_csrf from require "helpers.csrf"
  (...) =>
    assert_csrf @
    fn @, ...

assert_editable = (thing) =>
  unless thing\allowed_to_edit @current_user
    yield_error "Don't have permission to edit"

not_found = { render: "not_found", status: 404 }

login_and_return_url = (url=ngx.var.request_uri, intent) =>
  @url_for "user_login", nil, {
    return_to: @build_url url
    :intent
  }

require_login = (fn) ->
  =>
    if @current_user
      fn @
    else
      if @req.cmd_mth == "GET"
        redirect_to: login_and_return_url @
      else
        redirect_to: @url_for "user_login"

require_admin = (fn) ->
  =>
    if @current_user and @current_user\is_admin!
      fn @
    else
      not_found

ensure_https = (fn) ->
  =>
    scheme = @req.headers['x-original-scheme']
    if scheme == "http" and config.enable_https
      url_opts = {k,v for k,v in pairs @req.parsed_url}
      url_opts.scheme = "https"
      url_opts.port = nil

      return status: 301, redirect_to: build_url url_opts

    fn @

-- this will return errors as json on test so we can check them, otherwise
-- works just like the built in capture_errors
capture_errors = (fn) ->
  app = require "lapis.application"

  app.capture_errors {
    on_error: =>
      if config._name == "test"
        return json: { errors: @errors }

      not_found
    fn
  }

capture_errors_404 = (fn) ->
  app = require "lapis.application"

  app.capture_errors {
    on_error: => not_found
    fn
  }

assert_page = =>
  assert_valid @params, {
    {"page", optional: true, is_integer: true}
  }

  @page = math.max 1, tonumber(@params.page) or 1
  @page


verify_return_to = (url) ->
  return false unless url
  return false if url == ""

  return url unless url\match("^%w+://") or url\match "^//"
  domain = url\match "//([^:/]+)"
  return false unless domain
  domain = domain\lower!

  return url if domain == config.host\match "^[^:]*"
  return url if domain\sub(-#config.host) == config.host

  false


{ :assert_editable, :generate_csrf, :assert_csrf, :with_csrf, :require_login,
  :require_admin, :not_found, :capture_errors_404, :ensure_https, :assert_page,
  :login_and_return_url, :verify_return_to, :capture_errors }
