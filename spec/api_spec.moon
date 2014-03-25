import log_in_user from require "spec.helpers"
import truncate_tables from require "lapis.spec.db"
import generate_token from require "lapis.csrf"

import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import
  Users
  ApiKeys
  from require "models"

describe "application.api", ->
  local user

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, ApiKeys
    user = Users\create "leafo", "leafo", "leafo@example.com"

  it "should create an api key", ->
    status, body = request "/api_keys/new", {
      post: {
        csrf_token: generate_token nil, user.id
      }
      headers: log_in_user(user)
    }

    assert.same 302, status
    assert.same 1, #ApiKeys\select!

