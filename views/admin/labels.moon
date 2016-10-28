
class AdminUsers extends require "widgets.page"
  @needs: {"approved_labels"}
  @include "widgets.table_helpers"

  inner_content: =>
    h2 "Labels"

    @column_table @approved_labels, {
      {"name", (label) ->
        a href: @url_for(label), label.name
      }
      "created_at"
    }

    h2 "Used labels that aren't approved"
    @column_table @uncreated_labels, {
      "label"
      "count"
      {"create", (t) ->

        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "label[name]", value: t.label
          button "Create"

      }
    }

    h2 "Add new approved label"
    fieldset ->
      legend "Label"

      form class: "form", method: "POST", ->
        @csrf_input!
        @render_errors!

        div class: "row", ->
          label ->
            div class: "label", "Label name"
          input type: "text", name: "label[name]"

        div class: "button_row", ->
          button "Create label"


