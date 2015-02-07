
with require "cloud_storage.http"
  .set require "lapis.nginx.http"

db = require "lapis.db"
lapis = require "lapis.init"

math.randomseed os.time!

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
  DownloadsDaily
  from require "models"

import
  handle_rock_upload
  handle_rockspec_upload
  from require "helpers.uploaders"

import
  assert_csrf
  assert_editable
  generate_csrf
  require_login
  require_admin
  capture_errors_404
  not_found
  ensure_https
  from require "helpers.app"

import concat, insert from table

import load_module, load_manifest from require "helpers.loaders"
import paginated_modules from require "helpers.modules"

class MoonRocks extends lapis.Application
  layout: require "views.layout"

  @enable "exception_tracking"

  @include "applications.api"
  @include "applications.user"
  @include "applications.manifest"
  @include "applications.modules"
  @include "applications.github"

  @before_filter =>
    @current_user = Users\read_session @
    @csrf_token = generate_csrf @

  handle_404: =>
    "Not found", status: 404

  "/console": require("lapis.console").make!

  [index: "/"]: ensure_https =>
    @page_description = "A website for submitting and distributing Lua rocks"
    root = Manifests\root!

    @recent_modules = Modules\select [[
      inner join manifest_modules
        on manifest_modules.module_id = modules.id and manifest_modules.manifest_id = ?
      order by modules.created_at desc limit 5
    ]], root.id, fields: "modules.*"

    Users\include_in @recent_modules, "user_id"


    @popular_modules = Modules\select "order by downloads desc limit 5"
    Users\include_in @popular_modules, "user_id"

    @downloads_daily = DownloadsDaily\fetch true, 30
    render: true

  [modules: "/modules"]: =>
    @title = "All Modules"
    paginated_modules @, Modules\paginated "order by name asc", {
      per_page: 50
      fields: "id, name, display_name, user_id, downloads, summary"
    }
    render: true

  [upload_rockspec: "/upload"]: require_login respond_to {
    before: =>
      @title = "Upload Rockspec"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @
      mod, version = handle_rockspec_upload @
      redirect_to: @url_for "module", user: @current_user, module: mod
  }

  [endorse_module: "/endorse/:user/:module"]: require_login capture_errors_404 respond_to {
    before: =>
      load_module @

    PUT: =>
      @module\endorse @current_user
      redirect_to: @url_for @module

    DELETE: =>
      endorsement = @module\endorsement @current_user
      endorsement and endorsement\delete!
      redirect_to: @url_for @module
  }

  [upload_rock: "/modules/:user/:module/:version/upload"]: capture_errors_404 require_login respond_to {
    before: =>
      load_module @
      @title = "Upload Rock"

    GET: =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
      assert_csrf @
      handle_rock_upload @
      redirect_to: @url_for "module_version", @
  }


  [manifest: "/m/:manifest"]: capture_errors_404 =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest"
    paginated_modules @, @manifest
    render: true

  [manifest_development: "/m/:manifest/development-only"]: capture_errors_404 =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest Development Only Modules"
    @development_only = true
    paginated_modules @, @manifest, dev_only: true
    render: "manifest"

  [about: "/about"]: =>
    @title = "About"
    render: true

  [changes: "/changes"]: =>
    @title = "Changes"
    render: true


  [search: "/search"]: =>
    trim_filter @params
    if @params.q
      @title = "Search '#{@params.q}'"
      manifests = unless @params.non_root
        { Manifests\root!.id }

      pcall ->
        pager = Modules\search @params.q, manifests
        @results = paginated_modules @, pager

      import slugify from require "lapis.util"
      user_query = slugify @params.q

      if #user_query != 0
        user_query = "%#{slugify @params.q}%"
        pager = Users\paginated "where slug like ?", user_query
        @user_results = pager\get_page!
    else
      @title = "Search"

    render: true

  [copy_module: "/copy/modules/:user/:module"]: require_admin capture_errors {
    on_error: =>
      if @module
        { render: true }
      else
        not_found

    respond_to {
      before: capture_errors_404 =>
        return unless load_module @

        for man in *@module\all_manifests!
          if man.name == "root"
            @in_root = true
            break

      GET: =>
        render: true

      POST: capture_errors =>
        trim_filter @params
        assert_valid @params, {
          { "username", exists: true }
        }

        import slugify from require "lapis.util"
        target_user = Users\find slug: slugify @params.username
        assert_error target_user, "could not find user"
        assert_error @module.user.id != target_user.id, "users are the same"

        new_module = @module\copy_to_user target_user, not not @params.take_root

        redirect_to: @url_for("module", user: target_user.slug, module: new_module.name)
    }

  }

  [new_manifest: "/new-manifest"]: require_login respond_to {
    GET: => render: true

    POST: capture_errors =>
      import ManifestAdmins from require "models"
      assert_csrf @

      trim_filter @
      assert_valid @params, {
        {"manifest_name", exists: true, max_length: 60}
        {"description", optional: true, max_length: 1024*5}
      }

      manifest = assert_error Manifests\create @params.manifest_name,
        not not @params.is_open, @params.description

      ManifestAdmins\create manifest, @current_user, true

      redirect_to: @url_for(manifest)
  }



