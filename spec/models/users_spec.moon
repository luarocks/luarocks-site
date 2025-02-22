factory = require "spec.factory"

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
