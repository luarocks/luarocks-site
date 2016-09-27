class RemoveLabel extends require "widgets.page"
  inner_content: =>
    h2 "Remove label '#{@label}' from #{@module.name}"
    @render_modules { @module }
    @render_errors!

    form method: "post", ->
      @csrf_input!
      p ->
        text "Are you sure you want to remove the label '#{@label}' from "
        a href: @url_for(@module), @module.name
        text "? "

      div class: "buttons", ->
        input type: "submit", value: "Yes, Remove"

    p ->
      a href: @url_for(@module), ->
        raw "&laquo; No, Return to module"

