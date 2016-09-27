class AddLabel extends require "widgets.page"
  inner_content: =>
    h2 "Add Label to Module"
    
    @render_modules { @module }

    a href: @url_for(@module), ->
      raw "&laquo; Return to module"

    h3 "Add"
    if next @labels
      @add_form!
    else
      text "There are no labels that can be added to this module at this time."

  add_form: =>
    @render_errors!
    form method: "POST", class: "form", ->
      @csrf_input!
      div class: "row", ->
        label "Labels"
        element "select", name: "label_id", ->
          for l in *@labels
            option value: l.id, l.name

      div class: "button_row", ->
        input type: "submit", value: "Add to Module"
