-- lapis.http replacement for the test config's mcp_client_metadata_http. It
-- lives outside spec/ because the test server only loads compiled modules
json = require "cjson"

CLAUDE_CODE_ID = "https://claude.ai/oauth/claude-code-client-metadata"
OTHER_CLIENT_ID = "https://client.example/client.json"

DOCUMENTS = {
  [CLAUDE_CODE_ID]: {
    client_id: CLAUDE_CODE_ID
    client_name: "Claude Code"
    client_uri: "https://claude.ai"
    redirect_uris: {"http://localhost/callback", "http://127.0.0.1/callback"}
    grant_types: {"authorization_code", "refresh_token"}
    response_types: {"code"}
    token_endpoint_auth_method: "none"
  }

  [OTHER_CLIENT_ID]: {
    client_id: OTHER_CLIENT_ID
    client_name: "Example Client"
    redirect_uris: {"http://localhost/callback"}
  }
}

request = (req) ->
  doc = DOCUMENTS[req.url]
  return 1, 404, {} unless doc

  req.sink json.encode doc
  req.sink nil
  1, 200, { "Cache-Control": "public, max-age=300" }

{ :request, :CLAUDE_CODE_ID, :OTHER_CLIENT_ID }
