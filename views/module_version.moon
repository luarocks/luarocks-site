Header = require "widgets.module_header"

import time_ago_in_words from require "lapis.util"

class ModuleVersion extends require "widgets.page"
  @es_module: [[
    import {CopyButton} from "copy_button";
    new CopyButton(widget_selector);
  ]]

  rock_url: (item) =>
    "/manifests/#{@user\url_key!}/#{item.rockspec_fname or item.rock_fname}"

  header_content: =>
    widget Header {
      admin_panel: @\admin_panel
    }

  inner_content: =>
    p ->
      text "Version #{@version.version_name} of #{@module\name_for_display!}"
      text " was uploaded #{time_ago_in_words @version.created_at}."
      if @version.revision > 1
        text " (revision #{@version.revision})"

      if @version.lua_version
        text " For #{@version.lua_version}"

      if @version.development
        text " This is a development version of the module."

      if @version.archived
        text " This is an archived version, it's not available in any manifest
        and can only be installed by referencing the rockspec or rock
        directly."

    h3 "Files"

    rows = {@version}
    for rock in *@rocks
      table.insert rows, rock

    @column_table rows, {
      {"fname", label: "File", (row) ->
        fname = row.rockspec_fname or row.rock_fname
        a href: @rock_url(row), fname
        if row.external_rockspec_url
          text " "
          span class: "external_link", ->
            text "("
            a {
              rel: "nofollow"
              href: row.external_rockspec_url
              "External"
            }
            text ")"
      }
      {"size", label: "Size", (row) ->
        if row.size
          text @format_bytes row.size
        else
          span class: "nil_value", "—"
      }
      {"sha256", label: "SHA-256", (row) -> @render_hash_cell row.sha256, truncate: 10}
      {"md5", label: "MD5", (row) -> @render_hash_cell row.md5}
    }


  admin_panel: =>
    return unless @module\allowed_to_edit @current_user

    div class: "admin_tools", ->
      span class: "label", "Version Owner: "
      a href: @url_for("upload_rock", @), "Upload Rock"
      raw " &middot; "
      a href: @url_for("edit_module_version", @), "Edit"
      raw " &middot; "
      a href: @url_for("delete_module_version", @), "Delete This Version"


