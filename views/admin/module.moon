import FileAudits from require "models"

class AdminModule extends require "widgets.admin.page"
  @needs: {"module"}

  inner_content: =>
    h2 ->
      a href: @url_for(@module), @module\name_for_display!

    fieldset ->
      legend "Admin tools"
      user = @module\get_user!
      a href: @url_for("add_to_manifest", user: user, module: @module), class: "button", "Add To Manifest"
      text " "
      a href: @url_for("edit_module", user: user, module: @module), class: "button", "Edit"
      text " "
      a href: @url_for("delete_module", user: user, module: @module), class: "button", "Delete"
      text " "
      a href: @url_for("copy_module", user: user, module: @module), class: "button", "Copy module to other user"

    @field_table @module, {
      "id"
      "name"
      "display_name"
      {"user_id", -> a href: @url_for("admin.user", id: @module.user_id), @module.user_id}
      "downloads"
      "followers_count"
      "stars_count"
      "current_version_id"
      "has_dev_version"
      {"labels", type: "json"}
      "created_at"
      "updated_at"
      {"summary", type: "collapse_pre", truncate: 60}
      {"description", type: "collapse_pre", truncate: 120}
      "license"
      "homepage"
    }

    h3 "Owner"
    user = @module\get_user!
    if user
      @field_table user, {
        {"id", -> a href: @url_for("admin.user", id: user.id), user.id}
        "username"
        "email"
      }

    h3 "Versions"
    versions = @module\get_versions!
    if next versions
      -- newest version first, each followed by its rocks
      versions = [v for v in *versions]
      table.sort versions, (a, b) -> a.id > b.id

      rows = {}
      for version in *versions
        table.insert rows, version
        for rock in *version\get_rocks!
          table.insert rows, rock

      hash = (value) ->
        if value
          span class: "hash", title: value, value\sub(1, 10) .. "…"

      @column_table rows, {
        "id"
        {"file", (obj) ->
          if obj.rock_fname
            span class: "rock_file", ->
              span class: "audit_type", obj.arch
              a href: @url_for(obj), obj.rock_fname
          else
            a href: @url_for(obj), ->
              strong obj.version_name
            if obj.id == @module.current_version_id
              span class: "version_tag", "current"
            if obj.development_version
              span class: "version_tag", "dev"
        }
        {"downloads", (obj) -> text @format_number obj.downloads}
        {"created", (obj) -> @render_date obj.created_at}
        {"sha256", (obj) -> hash obj.sha256}
        {"md5", (obj) -> hash obj.md5}
        {"latest audit", (obj) ->
          audits = obj\get_audits!
          if audit = audits[1]
            a href: @url_for("admin.audit", id: audit.id), ->
              result = audit\get_result!
              if result and type(result.verdict) == "string"
                span class: "audit_verdict verdict_#{result.verdict\gsub "[^%w_]", ""}", result.verdict
              else
                status = FileAudits.statuses\to_name audit.status
                span class: "audit_status status_#{status}", status

            if #audits > 1
              span class: "audit_count", " +#{#audits - 1} older"
        }
        {"", (obj) ->
          form action: @url_for("admin.audit_create"), method: "POST", ->
            input type: "hidden", name: "object_type", value: obj.rock_fname and "rock" or "version"
            input type: "hidden", name: "object_id", value: obj.id
            @csrf_input!
            button type: "submit", "Audit"
        }
      }
    else
      p class: "empty_table", "No versions"

    h3 "Manifests"
    if next @module\get_manifest_modules!
      @column_table @module\get_manifest_modules!, {
        {"manifest", value: (mm) -> mm\get_manifest! }
        "module_name"
        "created_at"
      }
    else
      p class: "empty_table", "Not in any manifests"

    h3 "Audits"
    if next @module\get_audits!
      @column_table @module\get_audits!, {
        {"id", (audit) -> a href: @url_for("admin.audit", id: audit.id), audit.id}
        {"file", (audit) ->
          span class: "audit_type", FileAudits.object_types\to_name audit.object_type
          if object = audit\get_object!
            @render_model object
        }
        {"status", (audit) ->
          status = FileAudits.statuses\to_name audit.status
          span class: "audit_status status_#{status}", status
        }
        {"verdict", (audit) ->
          result = audit\get_result!
          if result and type(result.verdict) == "string"
            span class: "audit_verdict verdict_#{result.verdict\gsub "[^%w_]", ""}", result.verdict
        }
        "created_at"
      }
    else
      p class: "empty_table", "No audits"
