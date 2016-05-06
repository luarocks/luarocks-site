import time_ago_in_words from require "lapis.util"

Header = require "widgets.module_header"

import basic_format from require "helpers.html"

class Module extends require "widgets.page"
  content: =>
    div class: @@css_classes!, ->
      @header!

      if root = @module\in_root_manifest!
        div class: "installer", ->
          if @dev_only!
            @term_snippet "luarocks install --server=#{root\source_url @, true} #{@module.name}"
          else
            @term_snippet "luarocks install #{@module.name}"

      div class: "main_column", ->
        @inner_content!

  header: =>
    widget Header {
      admin_panel: @\admin_panel
    }

  dev_only: =>
    return false unless next @versions

    for v in *@versions
      return false unless v.development

    true

  inner_content: =>
    if description = @module.description
      if description != @module.summary
        div class: "description", ->
          raw basic_format description

    h3 "Versions"
    for v in *@versions
      div class: "version_row", ->
        url = "/modules/#{@user.slug}/#{@module.name}/#{v.version_name}"
        a href: url, v\name_for_display!

        if v.development
          span title: "Development version", class: "development_flag", "dev"

        if v.archived
          span title: "Not available in manifest", class: "archive_flag", "Archived"

        span class: "sub", title: "#{v.created_at} UTC", time_ago_in_words(v.created_at)
        span class: "sub", @plural v.downloads, "download", "downloads"

    if @dependencies and next @dependencies
      h3 "Dependencies"
      for d in *@dependencies
        div class: "dependency_row", ->
          if d.manifest_module
            mod = d.manifest_module\get_module!
            a href: @url_for(mod), mod\name_for_display!
          else
            text d.dependency_name

          if v = d\parse_version!
            text " "
            span class: "dep_version_name sub", v

    if next @depended_on
      h3 "Dependency for"
      for i, mod in ipairs @depended_on
        text ", " unless i == 1
        a href: @url_for(mod), mod\name_for_display!

    can_edit = @module\allowed_to_edit @current_user
    if next @labels
      h3 "Labels"
      for i,l in ipairs @labels
        div class: "label_row", ->
          a href: @url_for("modules_label", label: l.name), l.name
          if can_edit
            span class: "sub", ->
              text " ("
              a href: 
                @url_for("remove_label",user: @user.slug, module: @module.name, label_id: l.id),
                "remove"
              text ")"

    
    if next @manifests
      h3 "Manifests"
      for m in *@manifests
        @manifest = m
        div class: "manifest_row", ->
          a href: @url_for("manifest", @), ->
            code m.name

          if can_edit
            span class: "sub", ->
              text " ("
              a href: @url_for("remove_from_manifest", @), "remove"
              text ")"

        @manifest = nil

  admin_panel: =>
    return unless @module\allowed_to_edit @current_user
    div class: "admin_tools", ->
      span class: "label", ->
        if @current_user\is_admin!
          text "Admin Tools: "
        else
          text "Module Owner: "

      a href: @url_for("add_to_manifest", @), "Add To Manifest"
      raw " &middot; "
      a href: @url_for("add_label", @), "Add Label"
      raw " &middot; "
      a href: @url_for("edit_module", @), "Edit"
      raw " &middot; "
      a href: @url_for("delete_module", @), "Delete"

      if @current_user\is_admin!
        raw " &middot; "
        a href: @url_for("copy_module", @), "Copy module to other user"



