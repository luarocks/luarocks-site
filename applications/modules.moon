lapis = require "lapis"
db = require "lapis.db"

import
  capture_errors
  respond_to
  from require "lapis.application"

import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import
  assert_csrf
  assert_editable
  require_login
  capture_errors_404
  from require "helpers.apps"

import load_module from require "helpers.loaders"

import
  Versions
  Rocks
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

    @versions = Versions\select "where module_id = ? order by created_at desc", @module.id
    @manifests = @module\all_manifests!

    Versions\sort_versions @versions

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    render: true

  [edit_module: "/edit/modules/:user/:module"]: capture_errors_404 respond_to {
    before: =>
      load_module @
      assert_editable @, @module

      @title = "Edit '#{@module\name_for_display!}'"

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

    GET: =>
      render: true

    POST: capture_errors =>
      development = if @params.v
        assert_valid @params, {
          {"v", type: "table"}
        }
        @params.v.development

      @version\update development: not not development
      redirect_to: @url_for("module_version", @)

  }

  [module_version: "/modules/:user/:module/:version"]: capture_errors_404 =>
    return unless load_module @

    @title = "#{@module\name_for_display!} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    render: true

  [delete_module: "/delete/:user/:module"]: delete_module
  [delete_module_version: "/delete/:user/:module/:version"]: delete_module

