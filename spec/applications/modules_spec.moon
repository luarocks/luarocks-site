import use_test_server from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import request_as from require "spec.helpers"

factory = require "spec.factory"


import Modules, Versions, Followings, Users, Notifications, NotificationObjects from require "models"

describe "applications.modules", ->
  use_test_server!

  before_each ->
    truncate_tables Modules, Versions, Followings, Users, Notifications, NotificationObjects

  it "follows module", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/follow"
    assert.same 302, status

    followings = Followings\select!

    assert.same 1, #followings
    following = unpack followings

    assert.same current_user.id, following.source_user_id
    assert.same Followings.object_types.module, following.object_type
    assert.same mod.id, following.object_id

    current_user\refresh!
    mod\refresh!
    assert.same 1, current_user.following_count
    assert.same 1, mod.followers_count

  it "unfollows module", ->
    following = factory.Followings!
    mod = following\get_object!
    current_user = following\get_source_user!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/follow"
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
    status, res = request_as current_user, "/module/#{mod.id}/follow/follow"

    assert.same 1, Notifications\count!
    assert.same 1, NotificationObjects\count!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/follow"

    assert.same 0, Notifications\count!
    assert.same 0, NotificationObjects\count!


  it "stars module", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/star"
    assert.same 302, status

    followings = Followings\select!

    assert.same 1, #followings
    following = unpack followings

    assert.same current_user.id, following.source_user_id
    assert.same Followings.object_types.module, following.object_type
    assert.same mod.id, following.object_id

    current_user\refresh!
    mod\refresh!
    assert.same 1, current_user.following_count
    assert.same 1, mod.starrings_count

  it "unstars module", ->
    following = factory.Followings!
    mod = following\get_object!
    current_user = following\get_source_user!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/star"
    assert.same 302, status

    followings = Followings\select!
    assert.same 1, #followings

    current_user\refresh!
    mod\refresh!
    assert.same 1, current_user.following_count
    assert.same 0, mod.starrings_count

  it "does/undoes notification for starring", ->
    current_user = factory.Users!
    mod = factory.Modules!
    status, res = request_as current_user, "/module/#{mod.id}/follow/star"

    assert.same 1, Notifications\count!
    assert.same 1, NotificationObjects\count!

    status, res = request_as current_user, "/module/#{mod.id}/unfollow/star"

    assert.same 0, Notifications\count!
    assert.same 0, NotificationObjects\count!

