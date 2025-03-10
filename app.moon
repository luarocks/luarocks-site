
with require "cloud_storage.http"
  .set require "lapis.nginx.http"

db = require "lapis.db"
lapis = require "lapis.init"

import preload from require "lapis.db.model"

import
  assert_error
  capture_errors
  respond_to
  yield_error
  from require "lapis.application"

import assert_valid, with_params from require "lapis.validate"

types = require "lapis.validate.types"

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
  assert_page
  from require "helpers.app"

import concat, insert from table

import load_module, load_manifest from require "helpers.loaders"
import paginated_modules from require "helpers.modules"

logger = require "lapis.logging"
old_query = logger.query
logger.query = (q, time, ...) ->
  if ngx and ngx.ctx.query_log
    table.insert ngx.ctx.query_log, {q, time}

  old_query q, time, ...

class MoonRocks extends lapis.Application
  layout: require "views.layout"
  Request: require "helpers.request"

  @enable "exception_tracking"

  @include "applications.api"
  @include "applications.user"
  @include "applications.manifest"
  @include "applications.modules"
  @include "applications.github"
  @include "applications.admin"
  @include "applications.labels"

  @before_filter =>
    if ngx and ngx.ctx
      ngx.ctx.query_log = {}

    @current_user, @current_user_session = Users\read_session @

    if @current_user
      @current_user\update_last_active!

      if @current_user_session
        @current_user_session\update_last_active!

    @csrf_token = generate_csrf @

  handle_404: => not_found

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

    import ApprovedLabels from require "models"
    @labels = ApprovedLabels\select "order by name"
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

    POST: capture_errors {
      on_error: =>
        if @params.json
          { json: { errors: @errors } }
        else
          { render: true }

      =>
        assert_csrf @
        mod, version, is_new = handle_rockspec_upload @
        redirect_to = @url_for "module", user: @current_user, module: mod

        import UserActivityLogs from require "models"

        UserActivityLogs\create_from_request @, {
          user_id: @current_user.id
          action: if is_new then "module.create" else "module.add_version"
          source: "web"
          object_type: "module"
          object_id: mod.id
          data: {
            version_id: version.id
            version_name: version.version_name
          }
        }

        if @params.json
          { json: { success: true, :redirect_to } }
        else
          { :redirect_to }
    }
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
      rock = assert_error handle_rock_upload @

      import UserActivityLogs from require "models"

      UserActivityLogs\create_from_request @, {
        user_id: @current_user.id
        action: "module.version.upload_rock"
        source: "web"
        object_type: "version"
        object_id: @version.id
        data: {
          rock_id: rock.id
          rock_revision: rock.revision
          rock_arch: rock.arch
        }
      }

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

  [manifest_maintainers: "/m/:manifest/maintainers"]: capture_errors_404 =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest Maintainers"
    @pager = @manifest\find_admins!
    @admins = @pager\get_page!
    render: true

  [manifest_recent_versions: "/m/:manifest/recent"]: capture_errors_404 =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Recent Versions"
    @pager = @manifest\find_versions!
    assert_page @
    @versions = @pager\get_page @page
    render: true

  [about: "/about"]: =>
    @title = "About"
    render: true

  [changes: "/changes"]: =>
    @title = "Changes"
    render: true

  [search: "/search"]: capture_errors with_params {
    {"q", types.empty + types.limited_text(128), label: "query" }
    {"non_root", types.empty + types.any / true}
  }, (params) =>
    if query = params.q
      @title = "Search '#{query}'"
      @search_query = query

      manifests = unless params.non_root
        { Manifests\root!.id }

      @results = Modules\search query, manifests

      preload @results, user: {
        [preload]: {
          fields: "id, slug, username"
        }
      }, manifest_modules: "manifest"

      @user_results = Users\search(query)\get_page!
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

        for man in *@module\get_manifests!
          if man.name == "root"
            @in_root = true
            break

      GET: =>
        render: true

      POST: capture_errors with_params {
        {"username", types.limited_text 256}
        {"take_root", types.empty / false + types.any / true}
      }, (params) =>
        import slugify from require "lapis.util"
        target_user = Users\find slug: slugify params.username
        assert_error target_user, "could not find user"
        assert_error @module.user.id != target_user.id, "users are the same"

        new_module = @module\copy_to_user target_user, params.take_root

        redirect_to: @url_for("module", user: target_user.slug, module: new_module.name)
    }

  }

  [new_manifest: "/new-manifest"]: require_login respond_to {
    before: =>
      @title = "New manifest"

    GET: =>
      render: true

    POST: capture_errors with_params {
      {"manifest_name", types.limited_text 60}
      {"description", types.empty + types.limited_text 1024*5}
      {"is_open", types.empty / false + types.any / true}
    }, (params) =>
      import ManifestAdmins from require "models"
      assert_csrf @

      manifest = assert_error Manifests\create(
        params.manifest_name,
        params.is_open,
        params.description
      )

      ManifestAdmins\create manifest, @current_user, true

      redirect_to: @url_for(manifest)
  }

  [stats: "/stats"]: =>
    @title = "Stats"

    import cumulative_created from require "helpers.stats"

    @cumulative_users = cumulative_created Users, nil, "created_at", "week"
    @cumulative_modules = cumulative_created Modules, nil, "created_at", "week"
    @cumulative_versions = cumulative_created Versions, nil, "created_at", "week"

    render: true

  [popular_this_week: "/stats/this-week"]: capture_errors_404 =>
    @title = "Top this Lua modules this week"

    @days = @params.days or 7
    @days = math.min 60, math.max 1, @days

    @top_versions = DownloadsDaily\select "
      where date >= (now() at time zone 'utc' - ?::interval)
      group by version_id
      order by sum desc
      limit 20
    ", "#{@days} days", fields: "sum(count), version_id", load: false


    @top_new_versions = DownloadsDaily\select "
      where date >= (now() at time zone 'utc' - ?::interval)

      and version_id not in (
        select version_id from downloads_daily
          where
            date >= (now() at time zone 'utc' - ?::interval) and
            date < (now() at time zone 'utc' - ?::interval)
          group by version_id
          order by sum(count) desc
          limit 20
      )

      group by version_id
      order by sum desc
      limit 20
    ", "#{@days} days", "#{@days * 2} days", "#{@days} days", {
      fields: "sum(count), version_id"
      load: false
    }

    all_tuples = { unpack @top_versions }
    for t in *@top_new_versions
      table.insert all_tuples, t

    Versions\include_in all_tuples, "version_id"
    versions = [v.version for v in *all_tuples when v.version]
    Modules\include_in versions, "module_id"
    Users\include_in [v.module for v in *versions], "user_id"

    render: true

  [dependency_stats: "/stats/dependencies"]: capture_errors_404 =>
    import Dependencies from require "models"
    @top_depended = Dependencies\select "
      group by dependency_name
      order by count desc
      limit 30
    ", fields: "dependency_name, count(*)"

    Dependencies\preload_modules @top_depended
    @top_depended = [t for t in *@top_depended when t.manifest_module]

    render: true

  ["/security-incident-march-2019"]: =>
    render: "security_incident_march_2019"
