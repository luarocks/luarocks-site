import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import
  Manifests
  Users
  Versions
  from require "models"

describe "modules", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Manifests, Users, Versions

  it "should refresh has_dev_version with no dev versions", ->
    mod = factory.Modules!
    mod\update_has_dev_version!
    assert.falsy mod.has_dev_version

  it "should refresh has_dev_version with dev versions", ->
    mod = factory.Modules!
    v = factory.Versions development: true, module_id: mod.id

    mod\update_has_dev_version!
    assert.truthy mod.has_dev_version

