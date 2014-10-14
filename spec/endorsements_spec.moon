

import load_test_server, close_test_server, request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import
  Users
  Modules
  Endorsements
  from require "models"

factory = require "spec.factory"

describe "endorsements", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, Modules, Endorsements

  it "should create an endorsement", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    assert.truthy e
    assert.same user.id, e.user_id
    assert.same mod.id, e.module_id

  it "should not endorse twice", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    assert.truthy e
    e = Endorsements\endorse user, mod
    assert.falsy e

  it "should remove endorsement", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    e\delete!
