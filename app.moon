
http = require "lapis.nginx.http"
with require "cloud_storage.http"
  .set http

db = require "lapis.db"
lapis = require "lapis.init"

math.randomseed os.time!

MANIFEST_LUA_VERSIONS = { "5.1", "5.2" }

import
  assert_error
  capture_errors
  respond_to
  yield_error
  from require "lapis.application"

import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import
  ManifestModules
  Manifests
  Modules
  Rocks
  Users
  Versions
  from require "models"

import render_manifest from require "helpers.manifests"

import
  handle_rock_upload
  handle_rockspec_upload
  from require "helpers.uploaders"

import
  assert_csrf
  assert_editable
  generate_csrf
  require_login
  from require "helpers.apps"

import concat, insert from table

load_module = =>
  @user = assert Users\find(slug: @params.user), "Invalid user"
  @module = assert Modules\find(user_id: @user.id, name: @params.module\lower!), "Invalid module"
  @module.user = @user

  if @params.version
    @version = assert Versions\find({
      module_id: @module.id
      version_name: @params.version\lower!
    }), "Invalid version"

  if @route_name and (@module.name != @params.module or @version and @version.version_name != @params.version)
    url = @url_for @route_name, user: @user, module: @module, version: @version
    @write status: 301, redirect_to: url
    return false

  true

load_manifest = (key="id") =>
  @manifest = assert Manifests\find([key]: @params.manifest), "Invalid manifest id"

delete_module = respond_to {
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


class MoonRocks extends lapis.Application
  layout: require "views.layout"

  @include "applications.api"
  @include "applications.user"

  @before_filter =>
    @current_user = Users\read_session @
    @csrf_token = generate_csrf @

  handle_404: =>
    "Not found", status: 404

  [modules: "/modules"]: =>
    @title = "All Modules"
    @modules = Modules\select "order by name asc"
    Users\include_in @modules, "user_id"
    render: true

  [upload_rockspec: "/upload"]: respond_to {
    before: =>
      @title = "Upload Rockspec"

    GET: require_login =>
      render: true

    POST: capture_errors =>
      assert_csrf @
      mod, version = handle_rockspec_upload @
      redirect_to: @url_for "module", user: @current_user, module: mod
  }

  [index: "/"]: =>
    @page_description = "A website for submitting and distributing Lua rocks"

    @recent_modules = Modules\select "order by created_at desc limit 5"
    Users\include_in @recent_modules, "user_id"
    @popular_modules = Modules\select "order by downloads desc limit 5"
    Users\include_in @popular_modules, "user_id"

    render: true

  [root_manifest: "/manifest"]: =>
    modules = Manifests\root!\all_modules!
    render_manifest @, modules


  "/manifest-:version": capture_errors {
    on_error: =>
      "Not found", status: 404

    =>
      assert_valid @params, {
        { "version", one_of: MANIFEST_LUA_VERSIONS }
      }

      modules = Manifests\root!\all_modules!
      render_manifest @, modules, @params.version
  }

  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)

  [user_manifest: "/manifests/:user/manifest"]: =>
    user = assert Users\find(slug: @params.user), "Invalid user"
    render_manifest @, user\all_modules!

  "/manifests/:user/manifest-:version": capture_errors {
    on_error: =>
      "Not found", status: 404

    =>
      assert_valid @params, {
        { "version", one_of: MANIFEST_LUA_VERSIONS }
      }

      user = assert_error Users\find(slug: @params.user), "Invalid user"
      render_manifest @, user\all_modules!, @params.version
  }

  [user_profile: "/modules/:user"]: =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @title = "#{@user.username}'s Modules"
    @modules = Modules\select "where user_id = ? order by name asc", @user.id
    for mod in *@modules
      mod.user = @user

    render: true

  [module: "/modules/:user/:module"]: =>
    return unless load_module @

    @title = "#{@module\name_for_display!}"
    @page_description = @module.summary if @module.summary

    @versions = Versions\select "where module_id = ? order by created_at desc", @module.id
    @manifests = @module\all_manifests!

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    render: true

  [edit_module: "/edit/modules/:user/:module"]: respond_to {
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

  [module_version: "/modules/:user/:module/:version"]: =>
    return unless load_module @

    @title = "#{@module\name_for_display!} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    render: true

  [delete_module: "/delete/:user/:module"]: delete_module
  [delete_module_version: "/delete/:user/:module/:version"]: delete_module

  [upload_rock: "/modules/:user/:module/:version/upload"]: respond_to {
    before: =>
      load_module @
      @title = "Upload Rock"

    GET: require_login =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
      assert_csrf @
      handle_rock_upload @
      redirect_to: @url_for "module_version", @
  }

  [add_to_manifest: "/add_to_manifest/:user/:module"]: respond_to {
    before: =>
      load_module @
      @title = "Add Module To Manifest"

      already_in = { m.id, true for m in *@module\all_manifests! }
      @manifests = for m in *Manifests\select!
        continue if already_in[m.id]
        m

    GET: require_login =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_editable @, @module

      manifest_id = assert_error @params.manifest_id, "Missing manifest_id"
      manifest = assert_error Manifests\find(id: manifest_id), "Invalid manifest id"

      unless manifest\allowed_to_add @current_user
        yield_error "Don't have permission to add to manifest"

      assert ManifestModules\create manifest, @module
      redirect_to: @url_for("module", @)
  }


  [remove_from_manifest: "/remove_from_manifest/:user/:module/:manifest"]: respond_to {
    before: =>
      load_module @
      load_manifest @

    GET: require_login =>
      assert_editable @, @module
      @title = "Remove Module From Manifest"

      assert ManifestModules\find({
        manifest_id: @manifest.id
        module_id: @module.id
      }), "Module is not in manifest"

      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_editable @, @module

      ManifestModules\remove @manifest, @module
      redirect_to: @url_for("module", @)
  }

  [manifest: "/m/:manifest"]: =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest"
    @modules = @manifest\all_modules!
    Users\include_in @modules, "user_id"

    render: true


  [about: "/about"]: =>
    @title = "About"
    render: true

  [changes: "/changes"]: =>
    @title = "Changes"
    render: true

