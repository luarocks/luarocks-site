class CopyModule extends require "widgets.base"
  inner_content: =>
    h2 "Copy module"

    @render_modules { @module }
    p "Copy this module and all its versions to another users's account. "

    @render_errors!

    form action: "", method: "POST", class: "form", ->
      div class: "row", ->
        label for: "username_field", "Username"
        input type: "text", name: "username", id: "username_field"

      if @in_root
        div class: "wide_row", ->
          label ->
            input type: "checkbox", name: "take_root"
            text " Copied module takes position in root manifest"

      input type: "submit", value: "Copy Module"




