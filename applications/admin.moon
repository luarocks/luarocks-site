
lapis = require "lapis"

import not_found from require "helpers.app"

import
  respond_to
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_csrf from require "helpers.app"
import assert_valid from require "lapis.validate"

class MoonRocksAdmin extends lapis.Application
  @path: "/admin"

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [admin_become_user: "/become-user"]: respond_to {
    POST: capture_errors_json =>
      assert_csrf @
      import Users from require "models"

      assert_valid @params, {
        {"user_id", is_integer: true}
      }

      user = assert_error Users\find(@params.user_id), "invalid user"
      user\write_session @
      redirect_to: @url_for "index"
  }
