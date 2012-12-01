
import Widget from require "lapis.html"

require "moon"

class Index extends Widget
  content: =>
    text "session:"
    pre -> text moon.dump getmetatable(@session).__index

    if @current_user
      text "current_user:"
      pre -> text moon.dump @current_user
