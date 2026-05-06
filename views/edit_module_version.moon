class EditModuleVersion extends require "widgets.page"
  @es_module: [[
    import {CopyButton} from "copy_button";
    new CopyButton(widget_selector);
  ]]

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

        div class: "wide_row", ->
          label ->
            input type: "checkbox", name: "v[archived]", checked: @version.archived and "checked" or nil
            span class: "label", "Archived"
            p "This module's version is no longer listed in any manifests, but
            the files remain and can be explicitly installed by referencing the
            rockspec directly"

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

    mod = @version\get_module!
    user = mod\get_user!

    @column_table @rocks, {
      {"rock_fname", label: "File", (rock) -> a href: @url_for(rock), rock.rock_fname}
      {"size", label: "Size", (rock) ->
        if rock.size
          text @format_bytes rock.size
        else
          span class: "nil_value", "—"
      }
      {"sha256", label: "SHA-256", (rock) -> @render_hash_cell rock.sha256, truncate: 10}
      {"md5", label: "MD5", (rock) -> @render_hash_cell rock.md5}
      {"downloads", label: "Downloads"}
      {"created_at", label: "Uploaded"}
      {"actions", label: "", (rock) ->
        a {
          class: "button delete_btn"
          href: @url_for "delete_rock", {
            arch: rock
            version: @version
            module: mod
            :user
          }
          "Delete"
        }
      }
    }


