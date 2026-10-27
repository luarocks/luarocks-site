class McpConsent extends require "widgets.page"
  inner_content: =>
    consent = @consent

    -- client_name is whatever the client says it is, its client_id host
    -- can't be faked
    h2 ->
      text "Allow "
      strong consent.client_host
      text " to access your account?"

    p ->
      text "It identifies itself as "
      strong consent.client_name
      text ". You're logged in as "
      strong @current_user\name_for_display!
      text "."

    p "It will be able to use these tools from the LuaRocks MCP server:"

    ul class: "tool_list", ->
      for tool in *@mcp_tools
        li ->
          code tool.name
          if tool.annotations and tool.annotations.readOnlyHint
            span class: "tool_tag", "read only"

          div class: "tool_description", tool.description

    p ->
      text "Only allow this if you trust "
      strong consent.client_host
      text " and started connecting from it just now."

    if consent.redirect_loopback
      p ->
        strong "You'll be sent back to an app running on your own computer."
        text " Only continue if you started connecting from an app like Claude Code just now."
    else
      p ->
        text "You'll be sent back to "
        strong consent.redirect_host
        text "."

    form action: consent.action, method: "POST", class: "form", ->
      input type: "hidden", name: "consent_token", value: consent.consent_token

      div class: "button_row", ->
        input type: "submit", name: "approve", value: "Allow"
        text " "
        input type: "submit", value: "Cancel"
