
class UserSettingsLinkGithub extends require "widgets.user_settings_page"
  @needs: {
    "github_accounts"
  }

  settings_content: =>
    github = require "helpers.github"

    p ->
      text "Connected accounts can be used to
      log into your LuaRocks account. You can connect multiple GitHub accounts
      to the same LuaRocks account."

    p ->
      a {
        class: "button"
          href: github\login_url(@csrf_token)
      }, "Link a new GitHub account..."


    if next @github_accounts
      details ->
        summary "Legacy tools..."
        a href: @url_for("github_claim_modules"), "Claim modules with GitHub account"

      p ->
        strong "Linked accounts"

      ul ->
        for account in *@github_accounts
          li ->
            text account.github_login
            text " "
            span class: "sub", ->
              text "(connected "
              @render_date account.created_at
              text " | "
              a href: @url_for("github_remove", account), "Remove..."
              text ")"



