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

      headers = {"id", "version", "downloads", "created", "rockspec sha256", "rockspec md5", "latest audit", ""}

      element "table", class: "table column_table versions_table", ->
        thead ->
          tr ->
            for h in *headers
              td h

        for version in *versions
          tr class: "version_row", ->
            td -> a href: @url_for("admin.version", id: version.id), version.id
            td ->
              a href: @url_for(version), ->
                strong version.version_name
              if version.id == @module.current_version_id
                span class: "version_tag", "current"
              if version.development
                span class: "version_tag", "dev"
            td @format_number version.downloads
            td -> @render_date version.created_at
            td -> @render_short_hash version.sha256
            td -> @render_short_hash version.md5
            td -> @render_latest_audit version
            td -> @render_audit_button "version", version

          tr class: "rocks_row", ->
            td colspan: #headers, ->
              rocks = version\get_rocks!
              if next rocks
                @render_rocks_table rocks
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
    @render_audits_table @module\get_audits!
