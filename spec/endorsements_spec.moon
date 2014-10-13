

import load_test_server, close_test_server, request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import
  Users
  Modules
  Endorsements
  from require "models"

factory = require "spec.factory"

describe "endorsements", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, Modules, Endorsements

  it "should create an endorsement", ->
    mod = factory.Modules!
    user = factory.Users!

    assert Endorsements\create user_id: user.id, module_id: mod.id
