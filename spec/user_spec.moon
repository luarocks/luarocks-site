
import get_session from require "lapis.session"
import parse_cookie_string from require "lapis.util"
import generate_token from require "lapis.csrf"

import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import
  Users
  from require "models"


describe "application.user", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users


  it "should register a user", ->
    status, body, headers = request "/register", {
      post: {
        username: "leafo"
        password: "pword"
        password_repeat: "pword"
        email: "leafo@example.com"
        csrf_token: generate_token!
      }
    }

    assert.same 302, status
    assert.same headers.location, 'http://127.0.0.1/'
    user = unpack Users\select!
    assert.truthy user


  describe "with user", ->
    local user

    before_each ->
      user = Users\create "leafo", "pword", "leafo@example.com"

    it "should log in a user", ->
      status, body, headers = request "/login", {
        post: {
          username: "leafo"
          password: "pword"
          csrf_token: generate_token!
        }
      }

      assert.truthy headers.set_cookie
      session = get_session cookies: parse_cookie_string(headers.set_cookie)
      assert.same user.id, session.user.id


