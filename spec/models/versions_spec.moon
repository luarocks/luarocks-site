factory = require "spec.factory"

describe "models.versions", ->
  import
    Manifests
    Modules
    Users
    Versions
    Rocks
    from require "spec.models"

  it "allowed_to_edit only retrns true for owner/admin", ->
    v = factory.Versions!
    assert.falsy v\allowed_to_edit nil
    assert.truthy v\allowed_to_edit v\get_module!\get_user!
    assert.falsy v\allowed_to_edit factory.Users!
    assert.truthy v\allowed_to_edit factory.Users flags: 1


