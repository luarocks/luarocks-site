import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

describe "models.users", ->
  use_test_env!
 
  import Users from require "spec.models"

  it "should test the username generator", ->
    user = factory.Users!
    assert.same Users\generate_username(user.username), "#{user.username}-1"

  it "should generate a new username in case of nil", ->
      assert.same Users\generate_username(nil), "username"
