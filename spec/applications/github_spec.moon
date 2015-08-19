import use_test_server from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"
import get_current_server from require "lapis.spec.server"
import request_as from require "spec.helpers"

import GithubAccounts, Users, UserData from require "models"

factory = require "spec.factory"

describe "applications.github", ->
  use_test_server!

  local current_user, csrf_token

  before_each ->
    truncate_tables Users, UserData, GithubAccounts
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

