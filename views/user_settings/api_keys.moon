
class UserSettingsApiKeys extends require "widgets.user_settings_page"
  @needs: {
    "api_keys"
  }

  settings_content: =>
    if @show_revoked
      p ->
        text "Revoked API keys are no longer able to be used. "
        a href: @url_for("user_settings.api_keys"), "Return to active API keys"
    else
      p ->
        text "An API key is used to authenticate the "
        code "luarocks upload"
        text " command line tool to create and modify modules. Treat it like
        a password and don't share it with anyone. ("
        a href: "?revoked", "View revoked API keys"
        text ")"

    if #@api_keys == 0
      if @show_revoked
        p "You don't have any revoked API keys."
      else
        p "You currently don't have any keys."
    else

      @column_table @api_keys, {
        {"Comment#{@show_revoked and "" or " (enter to save)"}", (key) ->
          if key.revoked
            text key.comment or -> em "n/a"
          else
            form method: "post", class: "form", ->
              @csrf_input!
              input type: "hidden", name: "api_key", value: key.key
              input {
                type: "text"
                name: "comment"
                placeholder: "no comment"
                value: key.comment
              }
        }
        {"Key", (key) ->
          details ->
            summary ->
              code key.key\sub(1, 10) .. "…"

            input {
              type: "text"
              class: "rendered_key"
              readonly: true
              value: key.key
              onfocus: "this.select()"
            }
        }
        {"created_at", label: "Created at"}
        {"last_used_at", label: "Last used"}
        {"", (key) ->
          if key.revoked
            strong "Revoked"
            if key.revoked_at
              text " "
              @render_date key.revoked_at
          else
            a href: @url_for("delete_api_key", :key), "Revoke..."
        }
      }

    form class: "form", method: "post", action: @url_for"new_api_key", ->
      @csrf_input!
      div class: "button_row", ->
        button "Generate New Key"

    return if @show_revoked

    h3 "MCP clients"
    p ->
      text "MCP clients like Claude Code can use your account through the "
      code "https://luarocks.org/mcp"
      text " MCP server after you approve them. Connections expire and require
      reauthentication automatically after 90 days, but you can revoke them
      sooner from here."

    if #@mcp_grants == 0
      p "You don't have any MCP clients connected."
    else
      @column_table @mcp_grants, {
        {"Client", (grant) ->
          -- client_name is chosen by the client, the client_id host is what
          -- identifies it
          strong grant.client_name
          text " (#{grant.client_id\match("^https?://([^/]+)") or grant.client_id})"
        }
        {"created_at", label: "Connected"}
        {"last_used_at", label: "Last used"}
        {"access_expires_at", label: "Expires"}
        {"", (grant) ->
          form method: "post", action: @url_for("user_settings.revoke_mcp_grant", id: grant.id), ->
            @csrf_input!
            button class: "button", "Revoke"
        }
      }


