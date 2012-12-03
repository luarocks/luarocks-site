
import Widget from require "lapis.html"
class extends Widget
  content: =>
    h2 "Login"
    form action: @url_for"user_login", method: "POST", class: "form", ->

      div class: "row", ->
        label for: "username_field", "Username"
        input type: "text", name: "username", id: "username_field"

      div class: "row", ->
        label for: "password_field", "Password"
        input type: "password", name: "password", id: "password_field"

      div ->
        input type: "submit"

