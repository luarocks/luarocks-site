factory = require "spec.factory"
bit = require "bit"

describe "models.users", ->
  import
    Users
    UserData
    from require "spec.models"

  it "deletes a user", ->
    u = factory.Users!
    assert u\get_data!
    assert.truthy u\delete!

    assert.same 0, Users\count!
    assert.same 0, UserData\count!

  describe "flags", ->
    it "has_flag returns false when user has no flags", ->
      user = factory.Users!
      user\update flags: 0
      assert.falsy user\has_flag Users.flags.admin
      assert.falsy user\has_flag Users.flags.suspended
      assert.falsy user\has_flag Users.flags.spam

    it "has_flag returns true when user has specific flag", ->
      user = factory.Users!
      user\update flags: Users.flags.admin
      assert.truthy user\has_flag Users.flags.admin
      assert.falsy user\has_flag Users.flags.suspended
      assert.falsy user\has_flag Users.flags.spam

    it "update_flags can set a flag", ->
      user = factory.Users!
      user\update flags: 0
      user\update_flags admin: true
      assert.truthy user\has_flag Users.flags.admin
      assert.same Users.flags.admin, user.flags

    it "update_flags can unset a flag", ->
      user = factory.Users!
      user\update flags: Users.flags.admin
      user\update_flags admin: false
      assert.falsy user\has_flag Users.flags.admin
      assert.same 0, user.flags

    it "update_flags can set multiple flags at once", ->
      user = factory.Users!
      user\update flags: 0
      user\update_flags admin: true, suspended: true
      assert.truthy user\has_flag Users.flags.admin
      assert.truthy user\has_flag Users.flags.suspended
      expected = bit.bor(Users.flags.admin, Users.flags.suspended)
      assert.same expected, user.flags

    it "update_flags can toggle existing flags", ->
      user = factory.Users!
      user\update flags: bit.bor(Users.flags.admin, Users.flags.spam)
      user\update_flags admin: false, suspended: true
      assert.falsy user\has_flag Users.flags.admin
      assert.truthy user\has_flag Users.flags.suspended
      assert.truthy user\has_flag Users.flags.spam
      expected = bit.bor(Users.flags.suspended, Users.flags.spam)
      assert.same expected, user.flags

    it "helper methods work for checking flags", ->
      user = factory.Users!
      user\update flags: 0
      assert.falsy user\is_admin!
      assert.falsy user\is_suspended!
      assert.falsy user\is_spam!

      user\update flags: Users.flags.admin
      assert.truthy user\is_admin!

      user\update flags: Users.flags.suspended
      assert.truthy user\is_suspended!

      user\update flags: Users.flags.spam
      assert.truthy user\is_spam!
>>>>>>> 07bbfce (add bit flags to users table)
