
class UserForgotPassword extends require "widgets.base"
  content: =>
    div class: "user_forgot_password", ->
      if @token
        @set_password_form!
      else
        @request_reset_form!

  set_password_form: =>
    h2 "Reset Password"
    @render_errors!
    p "Enter a new password below to reset your password."
    form class: "form", action: @url_for"user_forgot_password", method: "post", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      input type: "hidden", name: "token", value: @params.token
      input type: "hidden", name: "id", value: @user.id

      div class: "row", ->
        label ->
          div class: "label", "Password"
        input type: "password", name: "password"

      div class: "row", ->
        label ->
          div class: "label", "Repeat Password"
        input type: "password", name: "password_repeat"

      div class: "button_row", ->
        input type: "submit", class: "button"
        text " or "
        a href: @url_for"user_login", "Log In"

  request_reset_form: =>
    if @params.sent
      p -> b "A password reset link has been sent to you email address."

    h2 "Reset Password"
    @render_errors!

    p "Enter the email address you registered with to be mailed a link to reset your password."

    form action: @url_for"user_forgot_password", method: "POST", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "row", ->
        label ->
          div class: "label", "Email"
        input type: "email", name: "email"

      div class: "button_row", ->
        input type: "submit", class: "button"
        text " or "
        a href: @url_for"user_login", "Log In"


