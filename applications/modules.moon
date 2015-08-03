lapis = require "lapis"
db = require "lapis.db"

import
  capture_errors
  respond_to
  assert_error
  from require "lapis.application"

import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import
  assert_csrf
  assert_editable
  require_login
  capture_errors_404
  from require "helpers.app"

import load_module from require "helpers.loaders"

import
  Versions
  Rocks
  Dependencies
  Modules
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
    @manifests = @module\get_manifests!
    @depended_on = @module\find_depended_on!

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

    GET: =>
      render: true

    POST: =>
      changes = @params.m

      trim_filter changes, {
        "license", "description", "display_name", "homepage"
      }, db.NULL

      @module\update changes
      redirect_to: @url_for("module", @)
  }

  [edit_module_version: "/edit/modules/:user/:module/:version"]: capture_errors_404 respond_to {
    before: =>
      return unless load_module @
      assert_editable @, @module

      @title = "Edit #{@module\name_for_display!} #{@version.version_name}"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @

      @params.v or= {}

      assert_valid @params, {
        {"v", type: "table"}
      }

      version_update = trim_filter @params.v
      development = not not version_update.development

      external_rockspec_url = if @current_user\is_admin!
        assert_valid version_update, {
          {"external_rockspec_url", type: "string", optional: true}
        }

        if url = version_update.external_rockspec_url
          unless url\match "%w+://"
            url = "http://" .. url
          url
        else
          db.NULL


      @version\update {
        :development
        :external_rockspec_url
      }

      redirect_to: @url_for("module_version", @)

  }

  [module_version: "/modules/:user/:module/:version"]: capture_errors_404 =>
    return unless load_module @

    @title = "#{@module\name_for_display!} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    render: true

  [delete_module: "/delete/:user/:module"]: delete_module
  [delete_module_version: "/delete/:user/:module/:version"]: delete_module

  [follow_module: "/module/:module_id/follow"]: capture_errors_404 =>
    assert_valid @params, {
      {"module_id", is_integer: true}
    }

    @module = assert_error Modules\find(@params.module_id),
      "invalid module"

    FollowingsFlow = require "flows.followings"
    followed = FollowingsFlow(@)\follow_object @module
    json: { success: followed }

  [unfollow_module: "/module/:module_id/unfollow"]: capture_errors_404 =>
    assert_valid @params, {
      {"module_id", is_integer: true}
    }

    @module = assert_error Modules\find(@params.module_id),
      "invalid module"

    FollowingsFlow = require "flows.followings"
    unfollowed = FollowingsFlow(@)\unfollow_object @module
    json: { success: unfollowed }
