
class UserSettings extends require "widgets.base"
  content: =>
    @render_errors!
    h2 "User Settings"

    @reset_password!

  reset_password: =>
    if @params.password_reset
      p ->
        b "Your password has been reset"

    h3 "Reset Password"
    form class: "form", action: @url_for"user_settings", method: "post", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "row", ->
        label ->
          div class: "label", "Current Password"
        input {
          type: "password",
          class: "medium_input"
          name: "password[current_password]"
        }

      div class: "row", ->
        label ->
          div class: "label", "New Password"
        input {
          type: "password",
          class: "medium_input"
          name: "password[new_password]"
        }

      div class: "row", ->
        label ->
          div class: "label", "New Password Again"
        input {
          type: "password",
          class: "medium_input"
          name: "password[new_password_repeat]"
        }

      div class: "button_row", ->
        button class: "button", "Submit"


