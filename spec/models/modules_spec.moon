import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import
  Manifests
  Modules
  Users
  Versions
  from require "models"

describe "models.modules", ->
  use_test_env!

  before_each ->
    truncate_tables Manifests, Users, Versions, Modules

  it "should refresh has_dev_version with no dev versions", ->
    mod = factory.Modules!
    mod\update_has_dev_version!
    assert.falsy mod.has_dev_version

  it "should refresh has_dev_version with dev versions", ->
    mod = factory.Modules!
    v = factory.Versions development: true, module_id: mod.id

    mod\update_has_dev_version!
    assert.truthy mod.has_dev_version

  it "allowed_to_edit only retrns true for owner/admin", ->
    mod = factory.Modules!
    assert.falsy mod\allowed_to_edit nil
    assert.truthy mod\allowed_to_edit mod\get_user!
    assert.falsy mod\allowed_to_edit factory.Users!
    assert.truthy mod\allowed_to_edit factory.Users flags: 1

  it "deletes module", ->
    mod = factory.Modules!
    mod\delete!

    user = mod\get_user!
    assert.same -1, user.modules_count

