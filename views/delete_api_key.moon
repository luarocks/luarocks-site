class DeleteApiKey extends require "widgets.base"
  content: =>
    h2 "Are you sure you want to revoke this api key?"
    pre @key.key
    div "Created on: #{@key.created_at}"

    p "Any tools using this key will no longer have access to MoonRocks."

    form action: @req.cmd_url, method: "POST", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      div class: "button_row", ->
        input type: "submit", value: "Revoke"
        text " "
        a href: @url_for"user_settings", "Cancel"
