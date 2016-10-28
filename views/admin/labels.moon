
class AdminUsers extends require "widgets.page"
  @needs: {"approved_labels"}
  @include "widgets.table_helpers"

  inner_content: =>
    h2 "Labels"

    @column_table @approved_labels, {
      "name"
      "created_at"
    }

    h2 "Add new approved label"
    fieldset ->
      legend "Label"

      form class: "form", method: "POST", ->
        @csrf_input!
        @render_errors!

        div class: "row", ->
          label ->
            div class: "label", "Username or email"
          input type: "text", name: "label[name]"

        div class: "button_row", ->
          button "Create label"


