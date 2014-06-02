
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
  from require "helpers.apps"

import concat, insert from table

load_module = =>
  @user = assert_error Users\find(slug: @params.user), "Invalid user"
  @module = assert_error Modules\find(user_id: @user.id, name: @params.module\lower!), "Invalid module"
  @module.user = @user

  if @params.version
    @version = assert_error Versions\find({
      module_id: @module.id
      version_name: @params.version\lower!
    }), "Invalid version"

  if @route_name and (@module.name != @params.module or @version and @version.version_name != @params.version)
    url = @url_for @route_name, user: @user, module: @module, version: @version
    @write status: 301, redirect_to: url
    return false

  true

load_manifest = (key="id") =>
  @manifest = assert_error Manifests\find([key]: @params.manifest), "Invalid manifest id"

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

paginated_modules = (object_or_pager, prepare_results) =>
  prepare_results or= (mods) ->
    Users\include_in mods, "user_id", fields: "id, slug, username"
    mods

  @page = tonumber(@params.page) or 1

  @pager = if object_or_pager.get_page
    object_or_pager.prepare_results = prepare_results
    object_or_pager
  else
    object_or_pager\find_modules {
      per_page: 50
      fields: "id, name, display_name, user_id, downloads, summary"
      :prepare_results
    }

  @modules = @pager\get_page @page

  if @page > 1 and not next @modules
    return redirect_to: @req.parsed_url.path

  if @page > 1 and @title
    @title ..= " - Page #{@page}"

  @modules

class MoonRocks extends lapis.Application
  layout: require "views.layout"

  @enable "exception_tracking"

  @include "applications.api"
  @include "applications.user"
  @include "applications.manifest"
  @include "applications.github"

  @before_filter =>
    @current_user = Users\read_session @
    @csrf_token = generate_csrf @

  handle_404: =>
    "Not found", status: 404

  [index: "/"]: =>
    @page_description = "A website for submitting and distributing Lua rocks"
    root = Manifests\root!

    @recent_modules = Modules\select [[
      inner join manifest_modules on manifest_modules.module_id = modules.id
      order by modules.created_at desc limit 5
    ]], fields: "modules.*"

    Users\include_in @recent_modules, "user_id"


    @popular_modules = Modules\select "order by downloads desc limit 5"
    Users\include_in @popular_modules, "user_id"

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

  [user_profile: "/modules/:user"]: capture_errors_404 =>
    @user = assert_error Users\find(slug: @params.user), "invalid user"

    @title = "#{@user.username}'s Modules"
    paginated_modules @, @user, (mods) ->
      for mod in *mods
        mod.user = @user
      mods

    render: true

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

  [add_to_manifest: "/add-to-manifest/:user/:module"]: capture_errors_404 require_login respond_to {
    before: =>
      load_module @
      assert_editable @, @module

      @title = "Add Module To Manifest"

      already_in = { m.id, true for m in *@module\all_manifests! }
      @manifests = for m in *Manifests\select!
        continue if already_in[m.id]
        m

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @

      assert_valid @params, {
        { "manifest_id", is_integer: true }
      }

      manifest = assert_error Manifests\find(id: @params.manifest_id), "Invalid manifest id"

      unless manifest\allowed_to_add @current_user
        yield_error "Don't have permission to add to manifest"

      assert ManifestModules\create manifest, @module
      redirect_to: @url_for("module", @)
  }


  [remove_from_manifest: "/remove-from-manifest/:user/:module/:manifest"]: capture_errors_404 require_login respond_to {
    before: =>
      load_module @
      load_manifest @

      assert_editable @, @module

    GET: =>
      @title = "Remove Module From Manifest"

      assert_error ManifestModules\find({
        manifest_id: @manifest.id
        module_id: @module.id
      }), "Module is not in manifest"

      render: true

    POST: =>
      assert_csrf @

      ManifestModules\remove @manifest, @module
      redirect_to: @url_for("module", @)
  }

  [manifest: "/m/:manifest"]: capture_errors_404 =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest"
    paginated_modules @, @manifest
    render: true

  [about: "/about"]: =>
    @title = "About"
    render: true

  [changes: "/changes"]: =>
    @title = "Changes"
    render: true


  [search: "/search"]: =>
    @title = "search"

    trim_filter @params
    if @params.q
      query = "%" .. @params.q\lower!\gsub("%%", "") .. "%"

      pager = Modules\paginated [[
        where name like ?
      ]], query

      @results = paginated_modules @, pager

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
      }

      import slugify from require "lapis.util"
      name = slugify @params.manifest_name

      manifest = assert_error Manifests\create name, not not @params.is_open
      ManifestAdmins\create manifest, @current_user, true

      redirect_to: @url_for(manifest)
  }

