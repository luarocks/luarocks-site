
import Widget from require "lapis.html"

require "moon"

class Index extends Widget
  content: =>
    text "session:"
    pre -> text moon.dump getmetatable(@session).__index

    if @current_user
      text "current_user:"
      pre -> text moon.dump @current_user

      ul ->
        li ->
          a href: @url_for"user_logout", "Logout"
    else
      ul ->
        li ->
          a href: @url_for"user_login", "Login"
        li ->
          a href: @url_for"user_register", "Register"

    h2 "Upload a file!"
    form action: @url_for"upload_file", method: "POST", enctype: "multipart/form-data", ->
      div -> input type: "file", name: "some_file"
      input type: "submit"


