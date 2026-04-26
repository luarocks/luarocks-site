
class UserTfaVerify extends require "widgets.page"
  inner_content: =>
    h2 "Two-factor authentication"
    @render_errors!

    p "Enter the 6-digit code from your authenticator app, or one of your 8-digit
    backup codes."

    form action: @url_for("user_tfa_verify"), method: "POST", class: "form", ->
      @csrf_input!
      input type: "hidden", name: "token", value: @params.token

      div class: "row", ->
        label for: "code_field", "Verification code"
        input {
          type: "text"
          name: "code"
          id: "code_field"
          autocomplete: "one-time-code"
          inputmode: "numeric"
          autofocus: "autofocus"
        }

      div class: "button_row", ->
        input type: "submit", value: "Verify"
        raw " &middot; "
        a href: @url_for("user_login"), "Cancel"
