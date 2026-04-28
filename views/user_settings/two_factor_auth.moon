
class UserSettingsTwoFactorAuth extends require "widgets.user_settings_page"
  settings_content: =>
    if @flash
      p ->
        b @flash

    if @has_totp
      p ->
        b "Two-factor authentication is enabled "
        text "on your account. You will be prompted for a 6-digit code from your
        authenticator app each time you log in."

      p "All changes below require your current password and a valid
      verification code (or backup code). Enter them once, then choose an
      action."

      form action: @url_for("user_settings.two_factor_auth"), method: "POST", class: "form", ->
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

        h3 "Update two-factor authentication settings"

        div class: "wide_row", ->
          label ->
            input {
              type: "checkbox"
              name: "require_for_uploads"
              checked: @requires_uploads and "checked" or nil
            }
            span class: "label", "Require 2FA for API uploads"
            span class: "sub", " — ", "Client will ask for 2fa code before module or rockspec upload"

        div class: "button_row", ->
          button class: "button", name: "action", value: "settings", "Update settings"

        h3 "Backup codes"

        p "Backup codes are stored securely and cannot be displayed again after
        enrollment. Regenerating will invalidate any existing backup codes and
        issue a fresh set."

        div class: "button_row", ->
          button class: "button", name: "action", value: "regenerate", "Regenerate backup codes"

        h3 "Disable two-factor authentication"

        p "Removes all two-factor authentication state from your account."

        div class: "button_row", ->
          button class: "button delete_btn", name: "action", value: "disable", "Disable two-factor authentication"
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
