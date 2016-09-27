class RemoveLabel extends require "widgets.page"
  inner_content: =>
    h2 "Remove Label: #{@module.name}"
    @render_modules { @module }
    @render_errors!

    form method: "POST", ->
      @csrf_input!
      div ->
        text "Are you sure you want to remove this label from "
        a href: @url_for(@module), @module.name
        text "? "
        input type: "submit", value: "Yes, Remove"

    div ->
      a href: @url_for(@module), ->
        raw "&laquo; No, Return to module"

