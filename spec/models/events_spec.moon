import use_test_env from require "lapis.spec"

factory = require "spec.factory"

describe "models.events", ->
  import Events, Modules, Users, TimelineEvents from require "spec.models"

  use_test_env!

  it "creates an event of user following user", ->
    user = factory.Users!
    followed_user = factory.Users!

    event = Events\create({
      user: user
      object: followed_user
      event_type: Events.event_types.subscription
    })

    user_timeline = user\timeline!

    assert.same user.id, event.source_user_id
    assert.same followed_user.id, event.object_id
    assert.same event.event_type, Events.event_types.subscription

    assert.same, #user_timeline, 1

  it "creates an event of user following a module", ->
    user = factory.Users!
    module = factory.Modules!

    event = Events\create({
      user: user
      object: module
      event_type: Events.event_types.subscription
    })

    user_timeline = user\timeline!

    assert.same user.id, event.source_user_id
    assert.same module.id, event.object_id
    assert.same event.event_type, Events.event_types.subscription

    assert.same, #user_timeline, 1

  it "creates an event of user starring a module", ->
    user = factory.Users!
    module = factory.Modules!

    event = Events\create({
      user: user
      object: module
      event_type: Events.event_types.bookmark
    })

    user_timeline = user\timeline!

    assert.same user.id, event.source_user_id
    assert.same module.id, event.object_id
    assert.same event.event_type, Events.event_types.bookmark

    assert.same, #user_timeline, 1

  it "deletes an event", ->
    user = factory.Users!
    module = factory.Modules!

    event = Events\create({
      user: user
      object: module
      event_type: Events.event_types.bookmark
    })

    event_id = event.id

    event\delete!

    assert.same Events\find(event_id), nil
    assert.same 0, #user\timeline!
