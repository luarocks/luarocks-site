
class EditModule extends require "widgets.base"
  inner_content: =>
    h2 ->
      text "Edit Module '#{@module\name_for_display!}' Version "
      code @version.version_name

    @render_errors!

    form action: @url_for("edit_module_version", @), method: "POST", class: "form", ->
      div class: "wide_row", ->
        label ->
          input type: "checkbox", name: "v[development]", checked: @version.development and "checked" or nil
          span class: "label", "Development version"
          p "This version is intended to be a development version of the
          module. This version will not be listed in the regular manifest but
          only in a development variant of the manifest."

      div class: "button_row", ->
        input type: "submit"
        raw " &middot; "
        a href: @url_for("module_version", @), "Cancel"

