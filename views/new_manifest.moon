class NewManifest extends require "widgets.page"
  inner_content: =>
    h2 "Create New Manifest"
    p "A manifest is a collection of modules that has its own URLs for
    installing modules from LuaRocks."

    @render_errors!

    form action: "", method: "post", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "wide_row", ->
        label ->
          div class: "label", "Manifest Name"
          input type: "text", name: "manifest_name", id: "manifest_name_field", autofocus: "autofocus"

      div class: "wide_row", ->
        label ->
          div class: "label", ->
            text "Description"
            span class: "sub", ->
              raw " &mdash; Optional"

          textarea name: "description"

      div class: "wide_row", ->
        label ->
          input type: "checkbox", name: "is_open"
          text "Allow submissions to this manifest from anyone"

      div class: "button_row", ->
        input type: "submit"

