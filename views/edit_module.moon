
class EditModule extends require "widgets.base"
  inner_content: =>
    h2 "Edit Module '#{@module\name_for_display!}'"

    @render_errors!

    form action: @url_for("edit_module", @), method: "POST", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "wide_row", ->
        label ->
          div class: "label", ->
            text "Display Name"
            span class: "sub", ->
              raw " &mdash; Leave blank to default to name of module"

          input type: "text", name: "m[display_name]", value: @module.display_name

      div class: "wide_row", ->
        label ->
          div class: "label", "License"
          input type: "text", name: "m[license]", value: @module.license

      div class: "wide_row", ->
        label ->
          div class: "label", "Homepage URL"
          input type: "text", name: "m[homepage]", value: @module.homepage

      div class: "wide_row", ->
        label ->
          div class: "label", "Description"
          textarea name: "m[description]", @module.description

      div class: "button_row", ->
        input type: "submit"
        raw " &middot; "
        a href: @url_for("module", @), "Cancel"


    p ->
      strong "Note: "
      text "All of this information is originally pulled from the first
        Rockspec uploaded. Changing anything here will only affect what is
        displayed on this site and not any Rockspec."

