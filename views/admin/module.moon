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
      versions = [v for v in *versions]
      table.sort versions, (a, b) -> a.id > b.id

      hash = (value) ->
        if value
          span class: "hash", title: value, value\sub(1, 10) .. "…"

      -- works for both versions (audits the rockspec) and rocks
      latest_audit = (object) ->
        audits = object\get_audits!
        if audit = audits[1]
          a href: @url_for("admin.audit", id: audit.id), ->
            result = audit\get_result!
            if result and type(result.verdict) == "string"
              span class: "audit_verdict verdict_#{result.verdict\gsub "[^%w_]", ""}", result.verdict
            else
              status = FileAudits.statuses\to_name audit.status
              span class: "audit_status status_#{status}", status

            if audit\is_likely_spam!
              text " "
              span class: "audit_verdict verdict_spam", "spam"

          if #audits > 1
            span class: "audit_count", " +#{#audits - 1} older"

      audit_button = (object_type, object) ->
        form action: @url_for("admin.audit_create"), method: "POST", ->
          input type: "hidden", name: "object_type", value: object_type
          input type: "hidden", name: "object_id", value: object.id
          @csrf_input!
          button type: "submit", "Audit"

      headers = {"id", "version", "downloads", "created", "rockspec sha256", "rockspec md5", "latest audit", ""}

      element "table", class: "table column_table versions_table", ->
        thead ->
          tr ->
            for h in *headers
              td h

        for version in *versions
          tr class: "version_row", ->
            td version.id
            td ->
              a href: @url_for(version), ->
                strong version.version_name
              if version.id == @module.current_version_id
                span class: "version_tag", "current"
              if version.development_version
                span class: "version_tag", "dev"
            td @format_number version.downloads
            td -> @render_date version.created_at
            td -> hash version.sha256
            td -> hash version.md5
            td -> latest_audit version
            td -> audit_button "version", version

          tr class: "rocks_row", ->
            td colspan: #headers, ->
              rocks = version\get_rocks!
              if next rocks
                @column_table rocks, {
                  {"rock id", (rock) -> text rock.id}
                  {"arch", (rock) -> text rock.arch}
                  {"file", (rock) -> a href: @url_for(rock), rock.rock_fname}
                  {"downloads", (rock) -> text @format_number rock.downloads}
                  {"created", (rock) -> @render_date rock.created_at}
                  {"sha256", (rock) -> hash rock.sha256}
                  {"md5", (rock) -> hash rock.md5}
                  {"latest audit", (rock) -> latest_audit rock}
                  {"", (rock) -> audit_button "rock", rock}
                }
              else
                em class: "empty_rocks", "No rocks"
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

          if audit\is_likely_spam!
            text " "
            span class: "audit_verdict verdict_spam", "spam"
        }
        "created_at"
      }
    else
      p class: "empty_table", "No audits"
