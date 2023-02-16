import use_test_server from require "lapis.spec"

import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.modules", ->
  use_test_server!

  import Modules, Versions, Followings, Users, Notifications, NotificationObjects from require "spec.models"

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

