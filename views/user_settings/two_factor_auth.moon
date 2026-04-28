
class UserSettingsTwoFactorAuth extends require "widgets.user_settings_page"
  settings_content: =>
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
        -- carries the toggled value for the "settings" action; ignored by other actions
        input {
          type: "hidden"
          name: "require_for_uploads"
          value: if @requires_uploads then "" else "on"
        }

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

        h3 "Require two-factor authentication for API uploads"

        if @requires_uploads
          p "Module uploads via the API currently require a fresh two-factor
          verification. Use the moonrocks/luarocks CLI; you will be prompted
          for a code on each upload session."
        else
          p "Optionally require a two-factor verification before any module
          upload via the API. This protects your modules even if your API key
          leaks."

        div class: "button_row", ->
          button class: "button", name: "action", value: "settings",
            if @requires_uploads
              "Stop requiring 2FA for API uploads"
            else
              "Require 2FA for API uploads"

        h3 "Backup codes"

        p "Backup codes are stored securely and cannot be displayed again after
        enrollment. Regenerating will invalidate any existing backup codes and
        issue a fresh set."

        div class: "button_row", ->
          button class: "button", name: "action", value: "regenerate", "Regenerate backup codes"

        h3 "Disable two-factor authentication"

        p "Removes all two-factor authentication state from your account."

        div class: "button_row", ->
          button class: "button", name: "action", value: "disable", "Disable two-factor authentication"
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
