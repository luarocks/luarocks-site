Header = require "widgets.module_header"

import time_ago_in_words from require "lapis.util"

class ModuleVersion extends require "widgets.page"
  rock_url: (item) =>
    "/manifests/#{@user\url_key!}/#{item.rockspec_fname or item.rock_fname}"

  content: =>
    div class: @@css_classes!, ->
      widget Header {
        admin_panel: @\admin_panel
      }

      div class: "main_column", ->
        @inner_content!

  inner_content: =>
    p ->
      text "Version #{@version.version_name} of #{@module\name_for_display!}
      was uploaded #{time_ago_in_words @version.created_at}."

      if @version.lua_version
        text " For #{@version.lua_version}"

      if @version.development
        text " This is a development version of the module."

      if @version.archived
        text " This is an archived version, it's not available in any manifest
        and can only be installed by referencing the rockspec or rock
        directly."

    h3 "Available Downloads"
    ul class: "rock_list", ->
      li class: "arch", ->
        a href: @rock_url(@version), "rockspec"
        if @version.external_rockspec_url
          text " "
          span class: "sub", ->
            text "("
            a {
              rel: "nofollow"
              href: @version.external_rockspec_url
              "External"
            }
            text ")"


      for rock in *@rocks
        li class: "arch", ->
          a href: @rock_url(rock), rock.arch


  admin_panel: =>
    return unless @module\allowed_to_edit @current_user

    div class: "admin_tools", ->
      span class: "label", "Version Owner: "
      a href: @url_for("upload_rock", @), "Upload Rock"
      raw " &middot; "
      a href: @url_for("edit_module_version", @), "Edit"
      raw " &middot; "
      a href: @url_for("delete_module_version", @), "Delete This Version"


