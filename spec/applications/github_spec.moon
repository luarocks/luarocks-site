import use_test_server from require "lapis.spec"
import get_current_server from require "lapis.spec.server"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.github", ->
  use_test_server!

  local current_user, csrf_token

  import Users, UserData, GithubAccounts from require "spec.models"

  before_each ->
    current_user = factory.Users!

    assert(get_current_server!, "server not loaded")\exec [[
      local github = require("helpers.github")
      github.access_token = function()
        return { access_token = "fake-token" }
      end

      github.user = function()
        return {
          id = 777,
          login = "test-account"
        }
      end
    ]]

    import generate_token from require "lapis.csrf"
    csrf_token = generate_token nil, current_user.id

  it "links github account", ->
    status = request_as current_user, "/github/auth", {
      post: {
        state: csrf_token
        hello: "world"
      }
    }

    assert.same 302, status

    assert.same 1, GithubAccounts\count!
    account = unpack GithubAccounts\select!
    assert.same 777, account.github_user_id
    assert.same "fake-token", account.access_token
    assert.same "test-account", account.github_login
    assert.same current_user.id, account.user_id

    assert.same "test-account", current_user\get_data!.github

  it "doesn't override user set github account", ->
    data = current_user\get_data!
    data\update github: "leafo"

    status = request_as current_user, "/github/auth", {
      post: {
        state: csrf_token
        hello: "world"
      }
    }

    data\refresh!
    assert.same "leafo", data.github

  describe "register and login", ->
    import get_session from require "lapis.session"
    import parse_cookie_string from require "lapis.util"

    it "register account using github", ->
      import generate_token from require "lapis.csrf"

      status, body, headers = request "/github/auth", {
        post: {
          state: generate_token!
        }
      }

      assert.same 302, status

      assert.same 1, GithubAccounts\count!
      account = unpack GithubAccounts\select!

      assert.same 777, account.github_user_id
      assert.same "fake-token", account.access_token
      assert.same "test-account", account.github_login

      assert.truthy headers.set_cookie
      session = get_session cookies: parse_cookie_string(headers.set_cookie)

      assert.is_not_nil session.user.id

    it "logs in existing user with github account", ->
      import generate_token from require "lapis.csrf"
      user = factory.Users!

      GithubAccounts\create {
        github_user_id: 777
        github_login: "hello-world"
        access_token: "12345"
        user_id: user.id
      }

      status, body, headers = request "/github/auth", {
        post: {
          state: generate_token!
          code: "xxxx"
        }
      }

      assert.same 302, status
      assert.same 1, GithubAccounts\count!

      assert.truthy headers.set_cookie
      session = get_session cookies: parse_cookie_string(headers.set_cookie)
      assert.same user.id, session.user.id




