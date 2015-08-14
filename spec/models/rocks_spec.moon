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

describe "models.rocks", ->
  use_test_env!

  before_each ->
    truncate_tables Manifests, Users, Modules, Versions, Rocks

  it "allowed_to_edit only retrns true for owner/admin", ->
    rock = factory.Rocks!
    assert.falsy rock\allowed_to_edit nil
    assert.truthy rock\allowed_to_edit rock\get_version!\get_module!\get_user!
    assert.falsy rock\allowed_to_edit factory.Users!
    assert.truthy rock\allowed_to_edit factory.Users flags: 1


