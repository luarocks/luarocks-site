
class NotFound extends require "widgets.base"
  content: =>
    h2 "404: Not found"

    @render_errors!

    p ->
      a href: @url_for("index"), "Go home"

  
