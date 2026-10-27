config = require("lapis.config").get!

import build_url from require "lapis.util"
import McpServer from require "lapis.mcp.server"
import McpHttpRouter from require "lapis.mcp.http"
import McpGrants from require "models"

-- the proxy in front of the app doesn't send X-Forwarded-Proto, which
-- lapis-mcp would otherwise derive the public URL from
PUBLIC_BASE_URL = if config.enable_https
  build_url { scheme: "https", host: config.host, port: config.ssl_port }

class LuarocksMcp extends McpServer
  @server_name: "luarocks"

  @add_tool {
    name: "me"
    description: "Get the luarocks.org account this connection is logged in as"
    inputSchema: { type: "object", properties: {} }
  }, (params) =>
    return nil, "This account is suspended or no longer exists" unless @user

    {
      id: @user.id
      username: @user.username
      display_name: @user.display_name
      profile_url: @req\build_url @req\url_for @user
      modules_count: @user.modules_count
      created_at: @user.created_at
    }

router = McpHttpRouter!

router\mount "/mcp", LuarocksMcp, {
  oauth: {
    grants: McpGrants
    allow_any_client: true
    public_base_url: PUBLIC_BASE_URL
    cache: ngx and ngx.shared and ngx.shared.mcp_clients

    -- the test server can't reach the network
    http: config.mcp_client_metadata_http and require config.mcp_client_metadata_http

    current_user: (route) -> route.current_user
    login_url: (route, return_to) -> route\url_for "user_login", nil, :return_to
    render_consent: (route, consent) ->
      route.consent = consent
      route.title = "Connect to LuaRocks"
      render: "mcp_consent"

    grant_created: (route, grant) ->
      import UserActivityLogs from require "models"
      UserActivityLogs\create_from_request route, {
        user_id: grant.user_id
        action: "account.create_mcp_grant"
        source: "web"
        data: {
          client_id: grant.client_id
          client_name: grant.client_name
        }
      }
  }

  load_session: (req, server) ->
    server.req = req
    user = server.auth.grant\get_user!
    server.user = user unless user and user\is_suspended!
}

router\application!
