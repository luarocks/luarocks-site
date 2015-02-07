class GithubRemove extends require "widgets.base"
  inner_content: =>
    h2 "Are you sure you want to unlink this account?"

    p ->
      text "The link to the GitHub account "
      strong @account.github_login
      text " will be removed from LuaRocks.org"

    @render_errors!
    form action: "", method: "POST", class: "form", ->
      div class: "button_row", ->
        input type: "hidden", name: "csrf_token", value: @csrf_token
        input type: "submit", value: "Remove link"

    p ->
      a href: @url_for("user_settings"), ->
        raw "&laquo; No, return to user settings"

