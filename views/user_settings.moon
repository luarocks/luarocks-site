
config = require("lapis.config").get!

class UserSettings extends require "widgets.base"
  content: =>
    @render_errors!
    h2 "User Settings"

    @edit_keys!
    hr!
    @reset_password!
    hr!
    @github_link!

  edit_keys: =>
    h3 id: "api_keys", "API Keys"
    p "An API key is used to authenticate the MoonRocks command line tool to
    create and modify modules. Treat it like a password and don't share it with
    anyone."

    if #@api_keys == 0
      p "You currently don't have any keys."
    else
      element "table", class: "table", ->
        thead ->
          tr ->
            td "Key"
            td "Created At"
            td ""

        for key in *@api_keys
          tr ->
            td -> code key.key
            td key.created_at
            td ->
              a href: @url_for("delete_api_key", :key), "Revoke"

    form class: "form", method: "post", action: @url_for"new_api_key", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      div class: "button_row", ->
        button "Generate New Key"


  reset_password: =>
    if @params.password_reset
      p ->
        b "Your password has been reset"

    h3 id: "reset_password", "Reset Password"
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


  github_link: =>
    github = require "helpers.github"

    h3 "Link GitHub account"

    p ->
      text "Link a GitHub account to automatically transfer ownership of
      modules from the "
      a href: @url_for("user_profile", user: "luarocks"), "luarocks"
      text " account to your own."

    p ->
      a href: github\login_url(@csrf_token), "Link a new account"

    if next @github_accounts
      p ->
        strong "Linked accounts"

      ul ->
        for account in *@github_accounts
          li ->
            text account.github_login
            text " "
            span class: "sub", ->
              text "("
              a href: "", "Remove"
              text ")"



