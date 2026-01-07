class AdminModule extends require "widgets.admin.page"
  @needs: {"module", "versions", "manifest_modules"}

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
    if #@versions > 0
      @column_table @versions, {
        "id"
        "version_name"
        "downloads"
        "development_version"
        "created_at"
      }
    else
      p class: "empty_table", "No versions"

    h3 "Manifests"
    if #@manifest_modules > 0
      @column_table @manifest_modules, {
        {"manifest", value: (mm) -> mm\get_manifest! }
        "module_name"
        "created_at"
      }
    else
      p class: "empty_table", "Not in any manifests"

    h3 "Audits"
    audits = {}
    for version in *@versions
      if version.audit
        table.insert audits, version.audit
      if version.rocks
        for rock in *version.rocks
          if rock.audit
            table.insert audits, rock.audit

    if #audits > 0
      import FileAudits from require "models"
      @column_table audits, {
        "id"
        {":get_object_type", label: "type"}
        {":get_object", label: "object"}
        {"status", FileAudits.statuses, label: "status"}
        "external_id"
        "created_at"
      }
    else
      p class: "empty_table", "No audits"
