
import load_test_server, close_test_server, request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import
  Users
  UserModuleTags
  Modules
  from require "models"

factory = require "spec.factory"

describe "tags", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, UserModuleTags, Modules

  it "should create user tagging", ->
    mod = factory.Modules!
    user = factory.Users!

    tag = UserModuleTags\create user_id: user.id, module_id: mod.id, tag: "Hello world"
    assert.same "hello-world", tag.tag

