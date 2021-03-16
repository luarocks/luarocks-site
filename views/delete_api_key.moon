class DeleteApiKey extends require "widgets.page"
  inner_content: =>
    h2 "Are you sure you want to revoke this API key?"
    pre @key.key

    @field_table @key, {
      {"comment", label: "Comment"}
      {"created_at", label: "Created At"}
      {"last_used_at", label: "Last Used"}
    }

    p "Any tools using this key will no longer have access to LuaRocks.org."

    form action: @req.cmd_url, method: "POST", class: "form", ->
      @csrf_input!

      div class: "button_row", ->
        input type: "submit", value: "Revoke"
        text " "
        a href: @url_for"user_settings.api_keys", "Cancel"
