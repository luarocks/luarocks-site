
import get_session from require "lapis.session"
import parse_cookie_string from require "lapis.util"
import generate_token from require "lapis.csrf"

import use_test_server from require "lapis.spec"

import request from require "spec.helpers"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "application.user", ->
  use_test_server!

  import Followings from require "models"
  import Users, UserData from require "spec.models"

  it "makes user data object", ->
    user = factory.Users!
    user\get_data!
    assert.same 1, UserData\count!

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
  
  it "should follow a user", ->
    user = factory.Users!
    followed_user = factory.Users!
    status, res = request_as user, "/modules/#{followed_user.username}/follow"
    assert.same 302, status

    followings = Followings\select!

    assert.same 1, #followings
    following = unpack followings

    assert.same user.id, following.source_user_id
    assert.same Followings.object_types.user, following.object_type
    assert.same followed_user.id, following.object_id

    user\refresh!
    followed_user\refresh!

    assert.same 1, user.following_count
    assert.same 1, followed_user.followers_count

  it "should unfollow a user", ->
    user = factory.Users!
    followed_user = factory.Users!

    -- Follows
    status, res = request_as user, "/modules/#{followed_user.username}/follow"

    assert.same 302, status

    -- Unfollow
    status, res = request_as user, "/modules/#{followed_user.username}/follow"

    followings = Followings\select!

    assert.same 2, #followings

    user\refresh!
    followed_user\refresh!

    assert.same 1, user.following_count
    assert.same 1, followed_user.followers_count

  describe "with user", ->
    local user
    local followed_user
      
    before_each ->
      user = Users\create "leafo", "pword", "leafo@example.com"
      followed_user = Users\create "leafo2", "pwordw", "leafo2@example.com"
        
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

    describe "api keys", ->
      it "gets api keys with no api keys", ->
        status, body, headers = request_as user, "/settings/api-keys"
        assert.same 200, status

      it "gets api keys with no api keys", ->
        factory.ApiKeys user_id: user.id
        status, body, headers = request_as user, "/settings/api-keys"
        assert.same 200, status

      it "sets comment", ->
        key = factory.ApiKeys user_id: user.id
        status, body, headers = request_as user, "/settings/api-keys", {
          post: {
            api_key: key.key
            comment: " Helllo world "
          }
        }

        assert.same 302, status
        key\refresh!
        assert.same "Helllo world", key.comment

      it "sets doesn't set comment on other users key", ->
        key = factory.ApiKeys!
        key\update comment: "okay"

        status, body, headers = request_as user, "/settings/api-keys", {
          post: {
            api_key: key.key
            comment: "hacked"
          }
        }

        assert.same 200, status
        key\refresh!
        assert.same "okay", key.comment
