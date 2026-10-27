import enum from require "lapis.db.model"

class AdminMcpGrants extends require "widgets.admin.page"
  @needs: {"grants", "pager"}

  inner_content: =>
    p "Clients users have connected to the MCP server at /mcp. Revoking a grant disconnects that client immediately."

    @filter_form (field) ->
      field "user_id"
      field "client_id"
      field "status", enum {
        "active"
        "pending"
        "expired"
      }

    form action: @url_for("admin.mcp_grants"), method: "POST", ->
      @csrf_input!
      input type: "hidden", name: "action", value: "delete_expired"
      button type: "submit", "Delete expired grants"

    @render_pager @pager

    @column_table @grants, {
      "id"
      {"user", value: (grant) -> grant\get_user!}
      "client_name"
      {"client_id", (grant) ->
        a href: @url_for("admin.mcp_grants", nil, client_id: grant.client_id), ->
          code grant.client_id
      }
      {"redirect_uri", (grant) -> code grant.redirect_uri}
      {"status", (grant) ->
        status = grant\get_status!
        span class: "grant_status status_#{status}", status
      }
      "last_used_at"
      "access_expires_at"
      "created_at"
      {"actions", (grant) ->
        form action: @url_for("admin.mcp_grants"), method: "POST", ->
          @csrf_input!
          input type: "hidden", name: "action", value: "revoke"
          input type: "hidden", name: "id", value: grant.id
          button type: "submit", "Revoke"
      }
    }

    @render_pager @pager
