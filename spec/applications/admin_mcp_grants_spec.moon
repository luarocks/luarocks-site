import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

db = require "lapis.db"
factory = require "spec.factory"

describe "admin mcp grants", ->
  use_test_server!

  import Users, McpGrants from require "spec.models"

  local admin, user

  in_hours = (hours) ->
    db.raw db.interpolate_query "(now() at time zone 'utc') + ? * interval '1 hour'", hours

  create_grant = (opts={}) ->
    values = {
      user_id: user.id
      client_id: "https://claude.ai/oauth/claude-code-client-metadata"
      client_name: "Claude Code"
      redirect_uri: "http://localhost:4567/callback"
      code_challenge: "challenge"
      resource: "http://localhost/mcp"
    }
    for k, v in pairs opts
      values[k] = v

    McpGrants\create values

  before_each ->
    admin = factory.Users flags: 1
    user = factory.Users!

  active = (hash="active-hash") -> create_grant access_hash: hash, access_expires_at: in_hours 1
  expired = -> create_grant access_hash: "expired-hash", access_expires_at: in_hours -1
  pending = -> create_grant code_hash: "code-hash", code_expires_at: in_hours 1

  it "forbids non-admins", ->
    status = request_as user, "/admin/mcp-grants"
    assert.not.same 200, status

  it "lists grants with their status", ->
    active!
    expired!
    pending!

    status, body = request_as admin, "/admin/mcp-grants"
    assert.same 200, status
    assert.truthy body\find "Claude Code", 1, true
    assert.truthy body\find "status_active", 1, true
    assert.truthy body\find "status_expired", 1, true
    assert.truthy body\find "status_pending", 1, true

  it "filters by status", ->
    active!
    expired!
    pending!

    status, body = request_as admin, "/admin/mcp-grants?status=active"
    assert.same 200, status
    assert.truthy body\find "status_active", 1, true
    assert.falsy body\find "status_expired", 1, true
    assert.falsy body\find "status_pending", 1, true

  it "revokes a grant", ->
    a = active!
    other = active "other-hash"

    status = request_as admin, "/admin/mcp-grants", {
      post: { action: "revoke", id: tostring a.id }
    }

    assert.same 302, status
    assert.same {other.id}, [g.id for g in *McpGrants\select!]

  it "deletes expired grants", ->
    a = active!
    expired!
    p = pending!

    status = request_as admin, "/admin/mcp-grants", {
      post: { action: "delete_expired" }
    }

    assert.same 302, status
    ids = {g.id, true for g in *McpGrants\select!}
    assert.same {[a.id]: true, [p.id]: true}, ids

  it "shows a user's grants on the admin user page", ->
    active!

    status, body = request_as admin, "/admin/user/#{user.id}"
    assert.same 200, status
    assert.truthy body\find "MCP Grants", 1, true
    assert.truthy body\find "claude-code-client-metadata", 1, true
