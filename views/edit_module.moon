import to_json from require "lapis.util"

class EditModule extends require "widgets.page"
  inner_content: =>
    @content_for "js_init", ->
      data = {
        suggested_labels: [l.name for l in *@suggested_labels]
        module: {
          id: @module_id
          labels: @module.labels and next(@module.labels) and @module.labels
        }
      }

      script type: "text/javascript", src: "/static/lib.js"
      script type: "text/javascript", src: "/static/main.js"

      script type: "text/javascript", ->
        raw "new M.EditModule(#{@widget_selector!}, #{to_json data});"


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

          input {
            type: "text"
            name: "m[display_name]"
            value: @module.display_name
            placeholder: @module.name
          }

      div class: "wide_row", ->
        label ->
          div class: "label", "Summary"
          input type: "text", name: "m[summary]", value: @module.summary

      div class: "wide_row", ->
        label ->
          div class: "label", "Labels"
          input {
            type: "text"
            class: "labels_input"
            placeholder: "comma separated list"
            "data-json_value": to_json @module.labels
            name: "m[labels]"
            value: table.concat @module.labels or {}, ", "
          }

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

