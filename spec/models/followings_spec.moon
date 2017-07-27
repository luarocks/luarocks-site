import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import Users, Modules, Followings from require "models"

describe "models.followings", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Modules, Followings

  it "creates follow", ->
    Followings\create {
      source_user_id: factory.Users!.id
      object_type: "module"
      object_id: factory.Modules!.id
      kind: Followings.kinds\for_db("subscription")
    }

