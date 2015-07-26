import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import
  Users
  Modules
  Endorsements
  from require "models"

factory = require "spec.factory"

describe "models.endorsements", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Modules, Endorsements

  it "should create an endorsement", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    assert.truthy e
    assert.same user.id, e.user_id
    assert.same mod.id, e.module_id

    mod\refresh!
    assert.same 1, mod.endorsements_count

  it "should not endorse twice", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    assert.truthy e
    e = Endorsements\endorse user, mod
    assert.falsy e

    mod\refresh!
    assert.same 1, mod.endorsements_count

  it "should remove endorsement", ->
    mod = factory.Modules!
    user = factory.Users!

    e = Endorsements\endorse user, mod
    e\delete!

    mod\refresh!
    assert.same 0, mod.endorsements_count

