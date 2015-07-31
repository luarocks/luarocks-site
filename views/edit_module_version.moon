
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
        input type: "submit"
        raw " &middot; "
        a href: @url_for("module_version", @), "Cancel"

