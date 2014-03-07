
import load_test_server, close_test_server, request
  from require "lapis.spec.server"

should_load = (url, expected_status=200) ->
  it "should load #{url} with #{expected_status}", ->
    assert.same expected_status, (request url)

import truncate_tables from require "lapis.spec.db"

import log_in_user from require "spec.helpers"

import
  Manifests
  Users
  from require "models"

describe "moonrocks", ->
  setup ->
    load_test_server!

    truncate_tables Manifests
    Manifests\create "root", true

  teardown ->
    close_test_server!

  should_load "/"
  should_load "/about"
  should_load "/m/root"
  should_load "/modules"
  should_load "/manifest"

  should_load "/login"
  should_load "/register"
  should_load "/user/forgot_password"

  -- logged out users shouldn't have access
  should_load "/upload", 302
  should_load "/settings", 302
  should_load "/api_keys/new", 302


  describe "with user", ->
    local user

    request_logged_in = (url, opts={}) ->
      opts.headers = log_in_user(user)
      request url, opts

    before_each ->
      truncate_tables Users
      user = Users\create "leafo", "leafo", "leafo@example.com"

    it "should load upload page", ->
      status, body = request_logged_in "/upload"
      assert.same 200, status

