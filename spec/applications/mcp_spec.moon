json = require "cjson"

import use_test_server from require "lapis.spec"
import request, request_as from require "spec.helpers"
import encode_query_string, parse_query_string from require "lapis.util"
import encode_base64 from require "lapis.util.encoding"
import CLAUDE_CODE_ID, OTHER_CLIENT_ID from require "helpers.mcp_client_metadata_stub"

factory = require "spec.factory"

REDIRECT_URI = "http://localhost:4567/callback"
VERIFIER = "test-code-verifier-0123456789-abcdefghijklmnopqrstuvwxyz"

s256_challenge = (verifier) ->
  digest = require "openssl.digest"
  h = digest.new "sha256"
  h\update verifier
  (encode_base64(h\final!)\gsub("+", "-")\gsub("/", "_")\gsub("=", ""))

authorize_url = (params={}) ->
  args = {
    response_type: "code"
    client_id: CLAUDE_CODE_ID
    redirect_uri: REDIRECT_URI
    state: "xyz"
    code_challenge: s256_challenge VERIFIER
    code_challenge_method: "S256"
  }
  for k, v in pairs params
    args[k] = v

  "/mcp/oauth/authorize?#{encode_query_string args}"

query_params = (url) ->
  parse_query_string url\match "%?(.*)$"

cookies_from = (headers) ->
  set_cookie = headers.set_cookie
  set_cookie = table.concat set_cookie, ", " if type(set_cookie) == "table"

  -- the test server joins multiple Set-Cookie headers with commas
  cookies = for cookie in set_cookie\gsub(", ([%w_]+=)", "\n%1")\gmatch "[^\n]+"
    cookie\match "^[^;]+"

  table.concat cookies, "; "

call_mcp = (token, method, params) ->
  headers = {
    "Accept": "application/json, text/event-stream"
    "Content-Type": "application/json"
  }
  headers["Authorization"] = "Bearer #{token}" if token

  request "/mcp", {
    method: "POST"
    :headers
    data: json.encode { jsonrpc: "2.0", id: 1, :method, :params }
  }

describe "applications.mcp", ->
  use_test_server!

  import Users, McpGrants from require "spec.models"

  it "advertises client ID metadata documents", ->
    status, body = request "/.well-known/oauth-authorization-server/mcp"
    assert.same 200, status
    metadata = json.decode body
    assert.same true, metadata.client_id_metadata_document_supported
    assert.same {"none"}, metadata.token_endpoint_auth_methods_supported
    assert.truthy metadata.authorization_endpoint\match "/mcp/oauth/authorize$"

  it "requires a token", ->
    status, _, headers = call_mcp nil, "ping"
    assert.same 401, status
    assert.truthy headers.www_authenticate\find "resource_metadata=", 1, true

  it "sends a logged out user to log in", ->
    status, _, headers = request authorize_url!
    assert.same 302, status
    assert.truthy headers.location\match "/login%?"
    return_to = query_params(headers.location).return_to
    assert.same CLAUDE_CODE_ID, query_params(return_to).client_id

  it "rejects a client on a private host", ->
    user = factory.Users!
    status = request_as user, authorize_url client_id: "https://10.0.0.1/client.json"
    assert.same 400, status

  describe "connecting", ->
    local user

    before_each ->
      user = factory.Users!

    show_consent = ->
      status, body, headers = request_as user, authorize_url!
      assert.same 200, status
      body, cookies_from headers

    -- attributes aren't written in a fixed order
    consent_token = (body) ->
      input = body\match '<input[^>]-name="consent_token"[^>]*>'
      input and input\match 'value="([^"]+)"'

    submit_consent = (body, cookies, approve=true) ->
      post = { consent_token: consent_token body }
      post.approve = "Allow" if approve
      request "/mcp/oauth/authorize", {
        method: "POST"
        :post
        headers: { Cookie: cookies }
      }

    exchange = (code) ->
      status, body = request "/mcp/oauth/token", {
        method: "POST"
        post: {
          grant_type: "authorization_code"
          :code
          client_id: CLAUDE_CODE_ID
          redirect_uri: REDIRECT_URI
          code_verifier: VERIFIER
        }
      }
      status, json.decode body

    connect = ->
      body, cookies = show_consent!
      status, _, headers = submit_consent body, cookies
      assert.same 302, status
      code = query_params(headers.location).code
      _, token = exchange code
      token.access_token

    it "shows the consent page", ->
      body = show_consent!
      assert.truthy body\find "claude.ai", 1, true
      assert.truthy body\find "Claude Code", 1, true
      assert.truthy body\find "app running on your own computer", 1, true
      assert.truthy consent_token body

    it "accepts a client from another host", ->
      status, body = request_as user, authorize_url client_id: OTHER_CLIENT_ID
      assert.same 200, status
      assert.truthy body\find "client.example", 1, true
      assert.truthy body\find "Example Client", 1, true

    it "connects and calls me", ->
      token = connect!
      assert.truthy token

      grant = unpack McpGrants\select!
      assert.same user.id, grant.user_id

      status, body = call_mcp token, "tools/call", { name: "me", arguments: {} }
      assert.same 200, status
      result = json.decode(body).result
      assert.falsy result.isError
      me = json.decode result.content[1].text
      assert.same user.id, me.id
      assert.same user.username, me.username
      assert.same "/modules/#{user.slug}", me.profile_url\match "/modules/.*$"

    it "logs the approval to the user's activity", ->
      import UserActivityLogs from require "spec.models"
      connect!

      logs = UserActivityLogs\select "where user_id = ?", user.id
      assert.same 1, #logs
      assert.same "account.create_mcp_grant", logs[1].action
      assert.same CLAUDE_CODE_ID, logs[1]\summarize!

    it "revokes clients when the password is changed", ->
      user\update_password "hello"
      token = connect!

      status = request_as user, "/settings/reset-password", {
        post: {
          "password[current_password]": "hello"
          "password[new_password]": "world"
          "password[new_password_repeat]": "world"
        }
      }

      assert.same 302, status
      assert.same 0, McpGrants\count!
      assert.same 401, (call_mcp token, "tools/call", { name: "me", arguments: {} })

    it "redirects with access_denied when cancelled", ->
      body, cookies = show_consent!
      status, _, headers = submit_consent body, cookies, false
      assert.same 302, status
      assert.same "access_denied", query_params(headers.location).error
      assert.same 0, McpGrants\count!

    it "returns an error for a suspended user", ->
      token = connect!
      user\refresh "flags"
      user\update_flags suspended: true

      status, body = call_mcp token, "tools/call", { name: "me", arguments: {} }
      assert.same 200, status
      result = json.decode(body).result
      assert.true result.isError

    it "removes the user's grants when the user is deleted", ->
      connect!
      assert.same 1, McpGrants\count!
      user\delete!
      assert.same 0, McpGrants\count!

    describe "module tools", ->
      import Modules, Versions, Rocks, Manifests, ManifestModules, DownloadsDaily from require "spec.models"

      call_tool_text = (token, name, arguments={}) ->
        status, body = call_mcp token, "tools/call", { :name, :arguments }
        assert.same 200, status
        result = json.decode(body).result
        assert.falsy result.isError, "#{name}: #{result.content[1].text}"
        result.content[1].text

      call_tool = (...) -> json.decode call_tool_text ...

      it "gets a module, a version and its downloads", ->
        mod = factory.Modules user_id: user.id, name: "lpeg"
        version = factory.Versions module_id: mod.id, version_name: "1.0.0-1"
        factory.Rocks version_id: version.id, arch: "src"
        ManifestModules\create Manifests\root!, mod
        version\increment_download!

        token = connect!

        info = call_tool token, "get_module", module: "lpeg"
        assert.same "lpeg", info.name
        assert.same {"1.0.0-1"}, [v.version for v in *info.versions]

        user\update username: "Some_User", slug: "some-user"
        info = call_tool token, "get_module_version", module: "lpeg", user: "Some_User", version: "1.0.0-1"
        assert.same {"src"}, [r.arch for r in *info.rocks]

        info = call_tool token, "get_module_downloads", module: "lpeg", days: 7
        assert.same 1, info.downloads
        assert.same 7, #info.daily
        assert.same 1, info.daily[7].downloads
        assert.same 1, info.versions[1].downloads_in_period

        assert.same "[]", call_tool_text token, "search_modules", query: "nothing-matches-this"

        assert.same {"lpeg"}, [m.name for m in *call_tool token, "my_modules"]

    describe "MCP clients settings", ->
      revoke = (as_user, grant) ->
        request_as as_user, "/settings/mcp-grants/#{grant.id}/revoke", {
          post: {}
        }

      it "lists the connection on the API keys page", ->
        connect!
        status, body = request_as user, "/settings/api-keys"
        assert.same 200, status
        assert.truthy body\find "MCP clients", 1, true
        assert.truthy body\find "Claude Code", 1, true
        assert.truthy body\find "/settings/mcp-grants/", 1, true

      it "revokes a client", ->
        import UserActivityLogs from require "spec.models"

        token = connect!
        grant = unpack McpGrants\select!

        status, _, headers = revoke user, grant
        assert.same 302, status
        assert.truthy headers.location\match "/settings/api%-keys$"
        assert.same 0, McpGrants\count!

        status = call_mcp token, "tools/call", { name: "me", arguments: {} }
        assert.same 401, status

        log = unpack UserActivityLogs\select "where user_id = ? and action = ?", user.id, "account.revoke_mcp_grant"
        assert.truthy log
        assert.same CLAUDE_CODE_ID, log\summarize!

      it "doesn't revoke another user's client", ->
        connect!
        grant = unpack McpGrants\select!

        revoke factory.Users!, grant
        assert.same 1, McpGrants\count!
