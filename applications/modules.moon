lapis = require "lapis"
db = require "lapis.db"

import
  capture_errors
  respond_to
  assert_error
  from require "lapis.application"

import assert_valid, with_params from require "lapis.validate"
types = require "lapis.validate.types"
shapes = require "helpers.shapes"

import
  assert_csrf
  assert_editable
  require_login
  capture_errors_404
  from require "helpers.app"

import load_module from require "helpers.loaders"

import preload from require "lapis.db.model"

import
  Versions
  Rocks
  Dependencies
  Modules
  Followings
  from require "models"

delete_module = capture_errors_404 respond_to {
  before: =>
    load_module @
    @title = "Delete #{@module\name_for_display!}?"

  GET: require_login =>
    assert_editable @, @module

    if @version and @module\count_versions! == 1
      return redirect_to: @url_for "delete_module", @params

    render: true

  POST: require_login capture_errors =>
    assert_csrf @
    assert_editable @, @module

    assert_valid @params, {
      { "module_name", equals: @module.name }
    }

    if @version
      if @module\count_versions! == 1
        error "can not delete only version"

      @version\delete!
      redirect_to: @url_for "module", @params
    else
      @module\delete!
      redirect_to: @url_for "index"
}


class MoonRocksModules extends lapis.Application
  [module: "/modules/:user/:module"]: capture_errors_404 =>
    return unless load_module @

    @title = "#{@module\name_for_display!}"
    @page_description = @module.summary if @module.summary

    @versions = @module\get_versions!
    preload @versions, module: "user"

    @manifests = @module\get_manifests!
    @depended_on = @module\find_depended_on!

    @module_following = @current_user and @current_user\find_follow @module
    @module_starring = @current_user and @current_user\find_star @module

    Versions\sort_versions @versions

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    unless @current_version
      vs = [v for v in *@versions]
      table.sort vs, (a, b) -> b.id < a.id
      @current_version = vs[1]

    if @current_version
      @dependencies = @current_version\get_dependencies!
      Dependencies\preload_modules @dependencies, @module\get_primary_manifest!

    render: true

  [edit_module: "/edit/modules/:user/:module"]: capture_errors_404 respond_to {
    before: =>
      load_module @
      assert_editable @, @module

      @title = "Edit #{@module\name_for_display!}"
      import ApprovedLabels from require "models"
      @suggested_labels = ApprovedLabels\select "order by name asc"

    GET: =>
      render: true

    POST: capture_errors with_params {
      {"m", types.params_shape {
        {"display_name", types.empty / db.NULL + types.limited_text 128}
        {"summary", types.empty / db.NULL + types.limited_text 512}
        {"license", types.empty / db.NULL + types.limited_text 128}
        {"description", types.empty / db.NULL + types.limited_text 1024*5}
        {"homepage", types.empty / db.NULL + types.limited_text(512) * shapes.url}

        {"labels", types.one_of {
          types.empty / -> {}
          types.limited_text(512) / Modules\parse_labels
        }}
      }}
    }, (params) =>
      assert_csrf @

      labels = params.m.labels
      params.m.labels = nil

      @module\update params.m
      @module\set_labels labels

      -- TODO: record user activity log

      redirect_to: @url_for("module", @)
  }

  [edit_module_version: "/edit/modules/:user/:module/:version"]: capture_errors_404 respond_to {
    before: =>
      return unless load_module @
      assert_editable @, @module

      @title = "Edit #{@module\name_for_display!} #{@version.version_name}"
      @rocks = @version\get_rocks!

    GET: =>
      render: true

    POST: capture_errors with_params {
      {"v", types.params_shape {
        {"development", types.empty / false + types.any / true}
        {"archived", types.empty / false + types.any / true}
        {"external_rockspec_url", types.nil + types.empty / db.NULL + shapes.url}
      }}
    }, (params) =>
      assert_csrf @

      unless @current_user\is_admin!
        params.v.external_rockspec_url = nil

      @version\update params.v

      -- TODO: record user activity log

      redirect_to: @url_for @version
  }

  [module_version: "/modules/:user/:module/:version"]: capture_errors_404 =>
    return unless load_module @

    @title = "#{@module\name_for_display!} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    @module_following = @current_user and @current_user\find_follow @module

    render: true

  [delete_module: "/delete/:user/:module"]: delete_module
  [delete_module_version: "/delete/:user/:module/:version"]: delete_module

  [delete_rock: "/delete/:user/:module/:version/:arch"]: require_login capture_errors_404 respond_to {
    before: =>
      load_module @
      assert_editable @, @rock

      @title = "Delete #{@module\name_for_display!}?"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @

      @rock\delete!
      redirect_to: @url_for @version
  }


  [follow_module: "/module/:module_id/follow/:type"]: require_login capture_errors_404 =>
    assert_valid @params, {
      {"module_id", is_integer: true}
      {"type", one_of: {"subscription", "bookmark"} }
    }

    @module = assert_error Modules\find(@params.module_id),
      "invalid module"

    @flow("followings")\follow_object @module, @params.type
    redirect_to: @url_for @module

  [unfollow_module: "/module/:module_id/unfollow/:type"]: require_login capture_errors_404 =>
    assert_valid @params, {
      {"module_id", is_integer: true}
      {"type", one_of: {"subscription", "bookmark"} }
    }

    @module = assert_error Modules\find(@params.module_id),
      "invalid module"

    @flow("followings")\unfollow_object @module, @params.type
    redirect_to: @url_for @module

  [audit_module: "/audit/modules/:user/:module"]: capture_errors_404 respond_to {
    before: =>
      load_module @
      @title = "Audit #{@module\name_for_display!}"

    GET: =>
      @versions = [v for v in *@module\get_versions! when not v.external_rockspec_url]
      preload @versions, "rocks", module: "user"

      captures = for v in *@versions
        { "/rock-cache/#{v.rockspec_key}" }

      diff = require "helpers.diff_match_patch"

      responses = if next captures
        { ngx.location.capture_multi captures }
      else
        { }

      for idx, response in ipairs responses
        version = @versions[idx]
        prev = responses[idx + 1] or { body: "" }
        version.rockspec_diff = assert diff.diff_main prev.body, response.body
        diff.diff_cleanupSemantic version.rockspec_diff

      render: true

  }
