class EditManifest extends require "widgets.page"
  inner_content: =>
    h2 "Edit Manifest '#{@manifest\name_for_display!}'"

    @render_errors!

    p ->
      a href: @url_for(@manifest), "« Return to manifest"

    form {
      method: "POST"
      action: @url_for "edit_manifest", manifest: @manifest.name
      class: "form"
    }, ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "wide_row", ->
        label ->
          div class: "label", ->
            text "Display Name"
            span class: "sub", ->
              raw " &mdash; Leave blank to default to name of manifest"

          input {
            type: "text"
            name: "display_name"
            value: @manifest.display_name
            placeholder: @manifest.name
          }

      div class: "wide_row", ->
        label ->
          div class: "label", "Description"
          textarea name: "description", @manifest.description

      div class: "button_row", ->
        button type: "submit", "Save changes"

