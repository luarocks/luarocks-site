
class UserRegister extends require "widgets.page"
  inner_content: =>
    h2 "Register"
    @render_errors!

    form action: @url_for"user_register", method: "POST", class: "form", ->
      @csrf_input!

      if @params.return_to
        input type: "hidden", name: "return_to", value: @params.return_to

      input type: "hidden", name: "intent", value: @params.intent

      div class: "row", ->
        label for: "username_field", "Username"
        input type: "text", name: "username", id: "username_field"

      div class: "row", ->
        label for: "password_field", "Password"
        input type: "password", name: "password", id: "password_field"

      div class: "row", ->
        label for: "password_field2", "Repeat Password"
        input type: "password", name: "password_repeat", id: "password_field2"

      div class: "row", ->
        label for: "email_field", "Email Address"
        input type: "email", name: "email", id: "email_field"

      div ->
        input type: "submit"
