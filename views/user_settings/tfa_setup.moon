
class UserSettingsTfaSetup extends require "widgets.user_settings_page"
  @es_module: [[
    if (typeof qrcode !== "undefined" && widget_params.otpauth_url) {
      const target = document.querySelector(widget_selector + " #tfa_qrcode");
      if (target) {
        const qr = qrcode(0, "M");
        qr.addData(widget_params.otpauth_url);
        qr.make();
        target.innerHTML = qr.createSvgTag({ scalable: true, margin: 2 });
      }
    }
  ]]

  js_init: =>
    super {
      otpauth_url: @otpauth_url
    }

  settings_content: =>
    p "Scan the QR code below with an authenticator app (Google Authenticator,
    1Password, Authy, etc.). If you cannot scan it, enter the secret manually."

    div id: "tfa_qrcode", style: "width: 220px; height: 220px; margin: 1em 0;", ""

    details ->
      summary "Show secret for manual entry"
      div class: "medium_input", ->
        code @secret

    script src: "/static/vendor/qrcode.min.js"

    h3 "Confirm"

    p "Once your authenticator is configured, enter the current 6-digit code
    along with your password to enable two-factor authentication."

    form action: @url_for("user_settings.tfa_confirm"), method: "POST", class: "form", ->
      @csrf_input!
      input type: "hidden", name: "secret", value: @secret

      div class: "row", ->
        label ->
          div class: "label", "Current Password"
        input {
          type: "password"
          class: "medium_input"
          name: "current_password"
          autocomplete: "current-password"
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
          autofocus: "autofocus"
        }

      div class: "button_row", ->
        button class: "button", "Enable two-factor authentication"
