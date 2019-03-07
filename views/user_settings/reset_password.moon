
class UserSettingsResetPassword extends require "widgets.user_settings_page"
  settings_content: =>
    if @params.reset_password
      p ->
        b "Your password has been changed"

    p "Please provide your current password to reset your password."

    form class: "form", method: "post", ->
      @csrf_input!

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


