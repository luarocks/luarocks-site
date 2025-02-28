import use_test_server from require "lapis.spec"

import request, request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.modules", ->
  use_test_server!

  import Modules, Versions, Followings, Users, Notifications, NotificationObjects from require "spec.models"

  describe "module actions", ->
    describe "case sensitivity and redirects", ->
      local user, mod

      before_each ->
        user = factory.Users username: "testuser"
        mod = factory.Modules user_id: user.id, name: "test_module"
        factory.Versions module_id: mod.id

      it "should redirect to canonical module name when case doesn't match", ->
        status, body, headers = request "/modules/testuser/TEST_MODULE"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module", headers.location

      it "should redirect to canonical user name when case doesn't match", ->
        status, body, headers = request "/modules/TestUser/test_module"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module", headers.location

      it "should redirect when both user and module case don't match", ->
        status, body, headers = request "/modules/TestUser/TEST_MODULE"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module", headers.location

      it "should not redirect when both user and module case match exactly", ->
        status, body, headers = request "/modules/testuser/test_module"
        assert.same 200, status
        assert.falsy headers.location

      it "should handle version case sensitivity correctly", ->
        version = factory.Versions module_id: mod.id, version_name: "1.0-1"

        -- Exact match shouldn't redirect
        status, body, headers = request "/modules/testuser/test_module/1.0-1"
        assert.same 200, status
        assert.falsy headers.location

        -- Request with uppercase module name but correct version name should redirect
        status, body, headers = request "/modules/testuser/TEST_MODULE/1.0-1"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module/1.0-1", headers.location

        -- Request with uppercase user, module, and version should redirect
        status, body, headers = request "/modules/TestUser/TEST_MODULE/1.0-1"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module/1.0-1", headers.location

        -- Test for dev version
        dev_version = factory.Versions module_id: mod.id, version_name: "scm-1", development: true

        -- Exact match shouldn't redirect
        status, body, headers = request "/modules/testuser/test_module/scm-1"
        assert.same 200, status
        assert.falsy headers.location

        -- Mixed case version should be found and redirected
        status, body, headers = request "/modules/testuser/test_module/SCM-1"
        assert.same 301, status
        assert.same "http://localhost:8080/modules/testuser/test_module/scm-1", headers.location

      it "should return 404 for non-existent module", ->
        status, body = request "/modules/testuser/nonexistent_module"
        assert.same 404, status

      it "should return 404 for non-existent user", ->
        status, body = request "/modules/nonexistentuser/test_module"
        assert.same 404, status

  it "follows module", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/subscription"
    assert.same 302, status

    followings = Followings\select!

    assert.same 1, #followings
    following = unpack followings

    assert.same current_user.id, following.source_user_id
    assert.same Followings.object_types.module, following.object_type
    assert.same Followings.types.subscription, following.type
    assert.same mod.id, following.object_id

    current_user\refresh!
    mod\refresh!
    assert.same 1, current_user.following_count
    assert.same 1, mod.followers_count

  it "unfollows module", ->
    following = factory.Followings type: "subscription"
    mod = following\get_object!
    current_user = following\get_source_user!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/subscription"
    assert.same 302, status

    followings = Followings\select!
    assert.same 0, #followings

    current_user\refresh!
    mod\refresh!
    assert.same 0, current_user.following_count
    assert.same 0, mod.followers_count

  it "does/undoes notification for follow", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/subscription"

    assert.same 1, Notifications\count!
    assert.same 1, NotificationObjects\count!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/subscription"

    assert.same 0, Notifications\count!
    assert.same 0, NotificationObjects\count!


  it "stars module", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/bookmark"
    assert.same 302, status

    followings = Followings\select!

    assert.same 1, #followings
    following = unpack followings

    assert.same current_user.id, following.source_user_id
    assert.same Followings.object_types.module, following.object_type
    assert.same Followings.types.bookmark, following.type
    assert.same mod.id, following.object_id

    current_user\refresh!
    mod\refresh!
    assert.same 1, current_user.stared_count
    assert.same 1, mod.stars_count

  it "unstars module", ->
    following = factory.Followings type: "bookmark"
    mod = following\get_object!
    current_user = following\get_source_user!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/bookmark"
    assert.same 302, status

    followings = Followings\select!
    assert.same 0, #followings

    current_user\refresh!
    mod\refresh!
    assert.same 0, current_user.stared_count
    assert.same 0, mod.stars_count

  it "does/undoes notification for starring", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/bookmark"

    assert.same 1, Notifications\count!
    assert.same 1, NotificationObjects\count!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/bookmark"

    assert.same 0, Notifications\count!
    assert.same 0, NotificationObjects\count!

