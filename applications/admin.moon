
lapis = require "lapis"
db = require "lapis.db"

import not_found from require "helpers.app"

import
  respond_to
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_csrf, assert_page from require "helpers.app"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

class MoonRocksAdmin extends lapis.Application
  @path: "/admin"
  @name: "admin."

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [cache: "/cache"]: capture_errors_json respond_to {
    before: =>
      @title = "Cache"

    GET: =>
      import get_keys from require "helpers.pagecache"
      @cache_keys = get_keys!
      render: true

    POST: =>
      assert_csrf @
      assert_valid @params, {
        {"action", one_of: {"purge_all", "purge_root", "purge"}}
      }

      import get_keys, purge_keys from require "helpers.pagecache"

      switch @params.action
        when "purge_root"
          import Manifests from require "models"
          removed = Manifests\root!\purge!
          return json: { :removed }

        when "purge_all"
          purge_keys [key for {key} in *get_keys!]

        when "purge"
          assert_valid @params, {
            {"key", exists: true, type: "string"}
          }

          purge_keys { @params.key }

      redirect_to: @url_for @route_name
  }

  [users: "/users"]: capture_errors_json =>
    @title = "Users"

    import Users from require "models"
    assert_page @

    assert_valid @params, {
      {"email", type: "string", optional: true}
    }

    if @params.email
      user = Users\find [db.raw "lower(email)"]: @params.email\lower!
      if user
        return redirect_to: @url_for("admin.user", id: user.id)

    @pager = Users\paginated "order by id desc", {
      per_page: 50
    }

    @users = @pager\get_page @page

    render: true

  [user: "/user/:id"]: capture_errors_json =>
    import Users, Followings from require "models"

    assert_valid @params, {
      {"id", is_integer: true}
    }

    @user = assert_error Users\find(id: @params.id), "invalid user"

    @title = "User '#{@user.username}'"

    @followings = Followings\select "where source_user_id = ?", @user.id
    Followings\preload_objects @followings

    render: true

  [become_user: "/become-user"]: respond_to {
    POST: capture_errors_json =>
      assert_csrf @
      import Users from require "models"

      assert_valid @params, {
        {"user_id", is_integer: true}
      }

      user = assert_error Users\find(@params.user_id), "invalid user"
      user\write_session @, type: "admin"
      redirect_to: @url_for "index"
  }

  [labels: "/labels"]: respond_to {
    before: =>
      @title = "Labels"

    GET: =>
      import ApprovedLabels from require "models"
      @approved_labels = ApprovedLabels\select!
      @uncreated_labels = ApprovedLabels\find_uncreated!
      render: true

    POST: capture_errors_json =>
      assert_csrf @

      assert_valid @params, {
        {"label", type: "table"}
        {"action", optional: true, one_of: {"delete"}}
      }

      trim_filter @params.label

      assert_valid @params.label, {
        {"name", exists: true}
      }

      import ApprovedLabels from require "models"

      label = switch @params.action
        when "delete"
          al = ApprovedLabels\find {
            name: @params.label.name
          }

          if al
            al\delete!
            al

        else -- create by default
          ApprovedLabels\create {
            name: @params.label.name
          }

      json: {
        success: label and true or false
        id: label and label.id
      }

  }

