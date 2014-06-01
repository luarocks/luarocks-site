class Errors extends require "widgets.base"
  inner_content: =>
    h2 @error_title or "There was an error with your request"

    @render_errors!

    p ->
      a href: @url_for("index"), "Go home"

