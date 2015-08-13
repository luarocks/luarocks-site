class GithubRemove extends require "widgets.page"
  inner_content: =>
    h2 "Are you sure you want to unlink this account?"

    p ->
      text "The link to the GitHub account "
      strong @account.github_login
      text " will be removed from LuaRocks.org"

    @render_errors!
    form action: "", method: "POST", class: "form", ->
      @csrf_input!

      div class: "button_row", ->
        input type: "submit", value: "Remove link"

    p ->
      a href: @url_for("user_settings.link_github"), ->
        raw "&laquo; No, return to account settings"

