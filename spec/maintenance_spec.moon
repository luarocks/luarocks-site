import use_test_env from require "lapis.spec"
import mock_request from require "lapis.spec.request"
import from_json from require "lapis.util"

factory = require "spec.factory"

describe "maintenance mode", ->
  use_test_env!

  import Manifests, Users, ApiKeys, UserSessions from require "spec.models"

  local config, App

  before_each ->
    Manifests\create "root", true
    config = require("lapis.config").get!
    config.maintenance_mode = true
    App = require "app"

  after_each ->
    config.maintenance_mode = false

  it "shows banner on read only pages", ->
    status, body = mock_request App, "/about"
    assert.same 200, status
    assert.truthy body\match "maintenance_banner"
    assert.falsy body\match "Log In"

  it "blocks non-GET requests", ->
    status = mock_request App, "/login", {
      method: "POST"
      post: { username: "leafo", password: "hello" }
    }
    assert.same 503, status

  it "blocks login and register pages", ->
    assert.same 503, (mock_request App, "/login")
    assert.same 503, (mock_request App, "/register")
    assert.same 503, (mock_request App, "/github/auth")

  it "blocks api with json error", ->
    key = factory.ApiKeys!
    status, body = mock_request App, "/api/1/#{key.key}/status"
    assert.same 503, status
    assert.truthy from_json(body).errors

  it "ignores sessions", ->
    import encode_session from require "lapis.session"

    user = factory.Users!
    user_session = UserSessions\create user_id: user.id, type: "login_password", ip: "127.0.0.1"

    request_opts = {
      cookies: {
        [config.session_name]: encode_session {
          user: { id: user.id, sid: user_session.id, key: user\salt! }
        }
      }
    }

    -- sanity check that the cookie logs in outside of maintenance mode
    config.maintenance_mode = false
    _, body = mock_request App, "/about", request_opts
    assert.truthy body\find "Log Out", 1, true

    config.maintenance_mode = true
    status, body = mock_request App, "/about", request_opts
    assert.same 200, status
    assert.falsy body\find "Log Out", 1, true
