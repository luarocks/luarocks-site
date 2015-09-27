
lapis = require "lapis"

import not_found from require "helpers.app"

import
  respond_to
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_csrf, assert_page from require "helpers.app"
import assert_valid from require "lapis.validate"

class MoonRocksAdmin extends lapis.Application
  @path: "/admin"
  @name: "admin."

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [users: "/users"]: =>
    assert_page @
    import Users from require "models"
    @pager = Users\paginated "order by id desc", {
      per_page: 50
    }

    @users = @pager\get_page @page

    render: true

  [become_user: "/become-user"]: respond_to {
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
