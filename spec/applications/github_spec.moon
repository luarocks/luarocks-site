import use_test_server from require "lapis.spec"
import get_current_server from require "lapis.spec.server"
import request, request_as from require "spec.helpers"

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

      github._api_request = function()
        erro("making api request from test")
      end

      github.primary_email = function()
        return "test@leafo.net"
      end

      github.user = function()
        return {
          id = 777,
          login = "test-account",
          email = "test@test.com"
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

  it "doesn't override user's github account when adding new account", ->
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

  it "adds a second account to user", ->
    GithubAccounts\create {
      github_user_id: 333
      github_login: "hello-world"
      access_token: "12345"
      user_id: current_user.id
    }

    request_as current_user, "/github/auth", {
      post: {
        state: csrf_token
      }
    }

    assert.same 2, GithubAccounts\count!
    assert.same {
      [333]: true
      [777]: true
    }, {a.github_user_id, true for a in *current_user\get_github_accounts!}

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

      new_user = account\get_user!
      assert.same "test-account", new_user.username

    it "handles username conflict when registering new account", ->
      factory.Users username: "test-account"

      import generate_token from require "lapis.csrf"

      status, body, headers = request "/github/auth", {
        post: {
          state: generate_token!
        }
      }

      account = unpack GithubAccounts\select!
      user = account\get_user!
      assert.not.same "test-account", user.username

    it "logs in existing user with github account", ->
      import generate_token from require "lapis.csrf"

      GithubAccounts\create {
        github_user_id: 777
        github_login: "hello-world"
        access_token: "12345"
        user_id: current_user.id
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
      assert.same current_user.id, session.user.id



