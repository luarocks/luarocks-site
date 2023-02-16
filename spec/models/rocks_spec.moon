factory = require "spec.factory"

describe "models.rocks", ->
  import
    Manifests
    Modules
    Users
    Versions
    Rocks
    from require "spec.models"

  it "allowed_to_edit only retrns true for owner/admin", ->
    rock = factory.Rocks!
    assert.falsy rock\allowed_to_edit nil
    assert.truthy rock\allowed_to_edit rock\get_version!\get_module!\get_user!
    assert.falsy rock\allowed_to_edit factory.Users!
    assert.truthy rock\allowed_to_edit factory.Users flags: 1


