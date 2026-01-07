
lapis = require "lapis"
db = require "lapis.db"

shapes = require "helpers.shapes"

import not_found from require "helpers.app"

import
  respond_to
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_csrf, assert_page from require "helpers.app"
import assert_valid, with_params from require "lapis.validate"

types = require "lapis.validate.types"

import preload from require "lapis.db.model"


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

  [modules: "/modules"]: capture_errors_json with_params {
    {"label", types.empty + types.valid_text}
    {"user_id", types.empty + types.db_id}
    {"sort", shapes.default("id") * types.one_of {
      "id"
      "downloads"
      "followers_count"
      "stars_count"
      "versions_count"
    }}
  }, (params) =>
    @title = "Modules"

    import Modules from require "models"
    assert_page @

    sort_clause = switch params.sort
      when "versions_count"
        "order by (select count(*) from versions where module_id = modules.id) desc"
      else
        "order by #{db.escape_identifier params.sort} desc"

    clause = db.clause {
      if params.label
        {"labels @> ?", db.array { params.label }}

      if params.user_id
        {"user_id = ?", params.user_id}
    }, prefix: "WHERE", allow_empty: true

    @pager = Modules\paginated "? #{sort_clause}", clause, {
      per_page: 50
      prepare_results: (mods) ->
        preload mods, "user", current_version: { module: "user" }
        mods
    }

    @modules = @pager\get_page @page
    render: true

  [module: "/module/:id"]: capture_errors_json with_params {
    {"id", types.db_id}
  }, (params) =>
    import Modules, ManifestModules from require "models"
    @module = assert_error Modules\find(id: params.id), "invalid module"

    @title = "Module '#{@module\name_for_display!}'"

    preload {@module}, "user", "current_version"
    @versions = @module\get_versions!
    preload @versions, "audit", rocks: "audit"
    @manifest_modules = ManifestModules\select "where module_id = ?", @module.id
    preload @manifest_modules, "manifest"

    render: true

  [users: "/users"]: capture_errors_json with_params {
    {"email", types.empty + types.trimmed_text}
    {"username", types.empty + types.trimmed_text}
    {"active_7d", types.empty + types.any / true}
    {"has_module", types.empty + types.any / true}
    {"has_star", types.empty + types.any / true}
    {"sort", shapes.default("id") * types.one_of {
      "id"
      "following_count"
      "modules_count"
      "followers_count"
      "stared_count"
      "last_active_at"
    }}
  }, (params) =>
    @title = "Users"

    import Users from require "models"
    assert_page @

    sort_clause = switch params.sort
      when "last_active_at"
        "order by last_active_at desc nulls last"
      else
        "order by #{db.escape_identifier params.sort} desc"

    clause = db.clause {
      if params.email
        {"lower(email) = ?", params.email\lower!}

      if params.username
        db.clause {
          {"lower(username) = ?", params.username\lower!}
          {"slug = ?", params.username\lower!}
        }, operator: "OR"

      if params.active_7d
        {"coalesce(last_active_at, created_at) > now() at time zone 'utc' - '7d'::interval"}

      if params.has_module
        {"modules_count > 0"}

      if params.has_star
        {"stared_count > 0"}

    }, prefix: "WHERE", allow_empty: true

    @pager = Users\paginated "? #{sort_clause}", clause, {
      per_page: 50
    }

    @users = @pager\get_page @page

    render: true

  [user: "/user/:id"]: capture_errors_json with_params {
    {"id", types.db_id}
    {"dump", types.empty / false + types.any / true}
  }, (params) =>
    import Users, Followings, ManifestAdmins, Manifests from require "models"
    @user = assert_error Users\find(id: params.id), "invalid user"

    if params.dump
      return json: @user\data_export!

    @title = "User '#{@user.username}'"
    preload @user\get_follows!, "object"

    @user_manifest_admins = ManifestAdmins\select "where user_id = ?", @user.id
    preload @user_manifest_admins, "manifest"

    render: true

  [become_user: "/become-user"]: respond_to {
    POST: capture_errors_json with_params {
      {"user_id", types.db_id}
    }, (params) =>
      assert_csrf @
      import Users from require "models"

      user = assert_error Users\find(params.user_id), "invalid user"
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

    POST: capture_errors_json with_params {
      {"label", types.params_shape {
        {"name", types.valid_text}
      }}
      {"action", types.empty + types.one_of {"delete"}}
    }, (params) =>
      assert_csrf @

      import ApprovedLabels from require "models"

      label = switch params.action
        when "delete"
          al = ApprovedLabels\find {
            name: params.label.name
          }

          if al
            al\delete!
            al

        else -- create by default
          ApprovedLabels\create {
            name: params.label.name
          }

      json: {
        success: label and true or false
        id: label and label.id
      }

  }

  [db_tables: "/tables"]: with_params {
    {"filter", types.empty + types.valid_text}
    {"sort", shapes.default("total_size") * types.one_of {
      "total_size",
      "indexes_size"
    }}
  }, (params) =>
    @title = "Tables"
    @inner_column_classes = "wide_column"

    order = switch params.sort
      when "total_size"
        "order by total_size desc"
      when "indexes_size"
        "order by indexes_size desc"
      else
        ""

    clause = db.clause {
      if params.filter
        {"table_name like ?", "%" .. params.filter .. "%"}
    }, prefix: "WHERE", allow_empty: true

    @tables = db.query [[
      SELECT
        table_name,
        pg_size_pretty(table_size) AS table_size,
        pg_size_pretty(indexes_size) AS indexes_size,
        pg_size_pretty(total_size) AS total_size
      FROM (
        SELECT
            table_name,
            pg_table_size(table_name) AS table_size,
            pg_indexes_size(table_name) AS indexes_size,
            pg_total_relation_size(table_name) AS total_size
        FROM (
            SELECT ('"' || table_schema || '"."' || table_name || '"') AS table_name
            FROM information_schema.tables
            ?
        ) AS all_tables
        ]] .. order .. [[
      ) AS pretty_sizes
    ]], clause

    render: true

  [audits: "/audits"]: capture_errors_json with_params {
    {"status", types.empty + types.one_of {"pending", "running", "completed", "failed"}}
    {"object_type", types.empty + types.one_of {"version", "rock"}}
  }, (params) =>
    @title = "Audits"
    import FileAudits from require "models"
    assert_page @

    clause = db.clause {
      if params.status
        {"status = ?", FileAudits.statuses\for_db params.status}

      if params.object_type
        {"object_type = ?", FileAudits.object_types\for_db params.object_type}
    }, prefix: "WHERE", allow_empty: true

    @pager = FileAudits\paginated "? order by id desc", clause, {
      per_page: 50
      prepare_results: (audits) ->
        preload audits, "object"
        audits
    }

    @audits = @pager\get_page @page
    render: true

  [audit_dispatch: "/audits/:id/dispatch"]: respond_to {
    POST: capture_errors_json with_params {
      {"id", types.db_id}
    }, (params) =>
      assert_csrf @
      import FileAudits from require "models"

      audit = assert_error FileAudits\find(params.id), "audit not found"

      ready_to_dispatch = audit\update {
        status: FileAudits.statuses.dispatched
      }, {
        where: db.clause {
          status: db.list {
            FileAudits.statuses.pending
            FileAudits.statuses.failed
            FileAudits.statuses.completed
          }
        }
      }

      assert_error ready_to_dispatch, "file audit is not in correct state to dispatch (must be pending, failed or completed)"

      import dispatch_audit from require "helpers.audit_dispatch"
      status, response = dispatch_audit audit

      -- on success will return a 204, ""
      json: { :status, :response }
  }

  [audit_create: "/audits/create"]: respond_to {
    POST: capture_errors_json with_params {
      {"object_type", types.one_of {"version", "rock"}}
      {"object_id", types.db_id}
    }, (params) =>
      assert_csrf @
      import FileAudits, Versions, Rocks from require "models"

      audit, err = switch params.object_type
        when "version"
          version = assert_error Versions\find(params.object_id), "version not found"
          FileAudits\audit_version version
        when "rock"
          rock = assert_error Rocks\find(params.object_id), "rock not found"
          FileAudits\audit_rock rock

      unless audit
        return json: { success: false, error: err or "failed to create audit" }

      json: { success: true, audit_id: audit.id }
  }


