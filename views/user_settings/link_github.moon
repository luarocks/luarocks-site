
class UserSettingsLinkGithub extends require "widgets.user_settings_page"
  @needs: {
    "github_accounts"
  }

  settings_content: =>
    github = require "helpers.github"

    p ->
      text "Link a GitHub account to automatically transfer ownership of
      modules from the "
      a href: @url_for("user_profile", user: "luarocks"), "luarocks"
      text " account to your own. Any modules that have a repository URL in
      their rockspec that matches your account will be copied into your
      account."

    p ->
      a href: github\login_url(@csrf_token), "Link a new account"

    p ->
      a href: @url_for("github_claim_modules"), "Claim modules with GitHub account"

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
              a href: @url_for("github_remove", account), "Remove"
              text ")"



