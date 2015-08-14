import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import
  Manifests
  Modules
  Users
  Versions
  Rocks
  from require "models"

describe "models.versions", ->
  use_test_env!

  before_each ->
    truncate_tables Manifests, Users, Modules, Versions, Rocks

  it "allowed_to_edit only retrns true for owner/admin", ->
    v = factory.Versions!
    assert.falsy v\allowed_to_edit nil
    assert.truthy v\allowed_to_edit v\get_module!\get_user!
    assert.falsy v\allowed_to_edit factory.Users!
    assert.truthy v\allowed_to_edit factory.Users flags: 1


