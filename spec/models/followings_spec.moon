factory = require "spec.factory"

describe "models.followings", ->
  import Users, Modules, Followings from require "spec.models"

  it "creates follow", ->
    Followings\create {
      source_user_id: factory.Users!.id
      object_type: "module"
      object_id: factory.Modules!.id
      type: "subscription"
    }

