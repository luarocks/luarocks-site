import time_ago_in_words from require "lapis.util"

class EditModuleVersion extends require "widgets.page"
  inner_content: =>
    h2 ->
      text "Edit "
      a href: @url_for(@version),
        "#{@module\name_for_display!} #{@version.version_name}"

    @render_errors!

    form action: @url_for("edit_module_version", @), method: "POST", class: "form", ->
      @csrf_input!

      div class: "development_group", ->
        div class: "wide_row", ->
          label ->
            input type: "checkbox", name: "v[development]", checked: @version.development and "checked" or nil
            span class: "label", "Development version"
            p "This version is intended to be a development version of the
            module. This version will not be listed in the regular manifest but
            only in a development variant of the manifest."

        if @current_user\is_admin!
          div class: "wide_row", ->
            label ->
              div class: "label", "Repository rockspec URL"
              p class: "sub", "If your development rockspec changes frequently
              you can serve it directly from your repository instead of the copy
              located on LuaRocks' server."

              input type: "text", name: "v[external_rockspec_url]", placeholder: "optional", value: @version.external_rockspec_url


      div class: "button_row", ->
        button "Save"
        raw " &middot; "
        a href: @url_for("module_version", @), "Cancel"

    @manage_rocks!

  manage_rocks: =>
    return unless next @rocks
    h2 "Manage rocks"
    ul class: "rock_list", ->
      for rock in *@rocks
        version = rock\get_version!
        mod = version\get_module!
        user = mod\get_user!

        li class: "arch", ->
          div class: "action_buttons", ->
            a {
              class: "button delete_btn"
              href: @url_for "delete_rock", {
                arch: rock
                :version
                module: mod
                :user
              }
              "Delete"
            }

          a href: @url_for(rock), rock.arch
          text " "
          span class: "timestamp", time_ago_in_words(rock.created_at)
          text " "
          span class: "downloads", @plural rock.downloads, "download", "downloads"
          text " "


