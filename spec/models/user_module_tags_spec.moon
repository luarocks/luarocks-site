import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import
  Users
  UserModuleTags
  Modules
  from require "models"

factory = require "spec.factory"

describe "models.user_module_tags", ->
  use_test_env!

  before_each ->
    truncate_tables Users, UserModuleTags, Modules

  it "should create user tagging", ->
    mod = factory.Modules!
    user = factory.Users!

    tag = UserModuleTags\create user_id: user.id, module_id: mod.id, tag: "Hello world"
    assert.same "hello-world", tag.tag


