
csrf = require "lapis.csrf"
config = require("lapis.config").get!

import yield_error from require "lapis.application"
import build_url from require "lapis.util"

generate_csrf = =>
  csrf.generate_token @, @current_user and @current_user.id

assert_csrf = =>
  csrf.assert_token @, @current_user and @current_user.id

assert_editable = (thing) =>
  unless thing\allowed_to_edit @current_user
    yield_error "Don't have permission to edit"

not_found = { render: "not_found", status: 404 }

require_login = (fn) ->
  =>
    if @current_user
      fn @
    else
      redirect_to: @url_for"user_login"

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

capture_errors_404 = (fn) ->
  import capture_errors from require "lapis.application"

  capture_errors {
    on_error: => not_found
    fn
  }

{ :assert_editable, :generate_csrf, :assert_csrf, :require_login,
  :require_admin, :not_found, :capture_errors_404, :ensure_https }
