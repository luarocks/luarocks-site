
import get_session from require "lapis.session"
import parse_cookie_string from require "lapis.util"

import use_test_server from require "lapis.spec"

import request from require "spec.helpers"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "application.user", ->
  use_test_server!

  import Followings from require "spec.models"
  import Users, UserData from require "spec.models"

  it "makes user data object", ->
    user = factory.Users!
    user\get_data!
    assert.same 1, UserData\count!

  it "should register a user", ->
    status, body, headers = request "/register", {
      csrf: true
      post: {
        username: "leafo"
        password: "pword"
        password_repeat: "pword"
        email: "leafo@example.com"
      }
    }

    assert.same 302, status
    assert.same 'http://localhost:8080/', headers.location
    user = unpack Users\select!
    assert.truthy user

  describe "with user", ->
    local user

    before_each ->
      user = Users\create "leafo", "pword", "leafo@example.com"

    it "should log in a user", ->
      status, body, headers = request "/login", {
        csrf: true
        post: {
          username: "leafo"
          password: "pword"
        }
      }

      assert.truthy headers.set_cookie
      session = get_session cookies: parse_cookie_string(headers.set_cookie)
      assert.same user.id, session.user.id

    it "should redirect to canonical user profile when case doesn't match", ->
      status, body, headers = request "/modules/LeAfO"
      assert.same 301, status
      assert.same "http://localhost:8080/modules/leafo", headers.location

    it "should not redirect when user slug matches exactly", ->
      status, body, headers = request "/modules/leafo"
      assert.same 200, status
      assert.falsy headers.location

    it "should handle user with mixed case username correctly", ->
      mixed_user = Users\create "MixedCase", "pword", "mixed@example.com"

      -- Should redirect to lowercase slug
      status, body, headers = request "/modules/MiXeDcAsE"
      assert.same 301, status
      assert.same "http://localhost:8080/modules/mixedcase", headers.location

      -- Should not redirect when using correct slug
      status, body, headers = request "/modules/mixedcase"
      assert.same 200, status
      assert.falsy headers.location

    it "should return 404 for non-existent user", ->
      status, body = request "/modules/nonexistentuser"
      assert.same 404, status

    it "should follow a user", ->
      other_user = factory.Users!
      status, res = request_as user, "/users/#{other_user.slug}/follow"
      assert.same 302, status

      followings = Followings\select!

      assert.same 1, #followings
      following = unpack followings

      assert.same user.id, following.source_user_id
      assert.same Followings.object_types.user, following.object_type
      assert.same other_user.id, following.object_id

      user\refresh!

      assert.same 1, user.following_count

    it "should unfollow a user", ->
      other_user = factory.Users!
      follow = factory.Followings {
        source_user_id: user.id
        object: other_user
        type: "subscription"
      }

      status, res = request_as user, "/users/#{other_user.slug}/unfollow"
      assert.same 302, status

      followings = Followings\select!

      assert.same 0, #followings

      user\refresh!

      assert.same 0, user.following_count

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
