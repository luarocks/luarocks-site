class AdminVersion extends require "widgets.admin.page"
  @needs: {"version"}

  inner_content: =>
    mod = @version\get_module!

    h2 ->
      a href: @url_for(mod), mod\name_for_display!
      text " "
      a href: @url_for(@version), @version.version_name
      text " ("
      a href: @url_for("admin.module", id: mod.id), "module admin"
      text ")"

    @field_table @version, {
      "id"
      {"module", -> @render_model mod}
      "version_name"
      "display_version_name"
      {"current", -> text mod.current_version_id == @version.id and "yes" or "no"}
      "development"
      "archived"
      "lua_version"
      "rockspec_fname"
      "rockspec_key"
      "external_rockspec_url"
      "source_url"
      "revision"
      "downloads"
      "rockspec_downloads"
      {"size", -> text @version.size and @filesize_format(@version.size) or ""}
      {"sha256", -> code @version.sha256 or ""}
      {"md5", -> code @version.md5 or ""}
      "created_at"
      "updated_at"
      {"latest audit", -> @render_latest_audit @version}
      {"", -> @render_audit_button "version", @version}
    }

    h3 "Rocks"
    rocks = @version\get_rocks!
    if next rocks
      @render_rocks_table rocks
    else
      p class: "empty_table", "No rocks"

    h3 "Rockspec audits"
    @render_audits_table @version\get_audits!
