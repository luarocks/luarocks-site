
class UserSettingsTwoFactorAuth extends require "widgets.user_settings_page"
  settings_content: =>
    if @has_totp
      p ->
        b "Two-factor authentication is enabled "
        text "on your account. You will be prompted for a 6-digit code from your
        authenticator app each time you log in."

      h3 "Disable two-factor authentication"

      p "Both your current password and a valid verification code (or backup
      code) are required to disable two-factor authentication."

      form action: @url_for("user_settings.tfa_disable"), method: "POST", class: "form", ->
        @csrf_input!

        div class: "row", ->
          label ->
            div class: "label", "Current Password"
          input {
            type: "password"
            class: "medium_input"
            name: "current_password"
          }

        div class: "row", ->
          label ->
            div class: "label", "Verification code"
          input {
            type: "text"
            class: "medium_input"
            name: "code"
            inputmode: "numeric"
            autocomplete: "one-time-code"
          }

        div class: "button_row", ->
          button class: "button", "Disable two-factor authentication"

      h3 "Backup codes"

      p "Backup codes are stored securely and cannot be displayed again after
      enrollment. Regenerating will invalidate any existing backup codes and
      issue a fresh set."

      form action: @url_for("user_settings.tfa_regenerate"), method: "POST", class: "form", ->
        @csrf_input!

        div class: "row", ->
          label ->
            div class: "label", "Current Password"
          input {
            type: "password"
            class: "medium_input"
            name: "current_password"
          }

        div class: "row", ->
          label ->
            div class: "label", "Verification code"
          input {
            type: "text"
            class: "medium_input"
            name: "code"
            inputmode: "numeric"
            autocomplete: "one-time-code"
          }

        div class: "button_row", ->
          button class: "button", "Regenerate backup codes"
    else
      if @params.disabled
        p ->
          b "Two-factor authentication has been disabled."

      p "Two-factor authentication adds a second step to your login: after
      entering your password you will be prompted for a 6-digit code from an
      authenticator app on your phone."

      p "We recommend enabling two-factor authentication on accounts that own
      published modules."

      div class: "button_row", ->
        a class: "button", href: @url_for("user_settings.tfa_setup"), "Enable two-factor authentication"
