import Flow from require "lapis.flow"

import Events, Followings, TimelineEvents, Users from require "models"

import assert_error from require "lapis.application"

class EventsFlow extends Flow
  expose_assigns: true

  new: (...) =>
    super ...
    assert_error @current_user, "must be logged in"

  create_event_and_deliver: (object, event_type) =>
    import preload from require "lapis.db.model"
      
    -- Creates the primary event
    event = Events\create({
      user: @current_user
      object: object
      event_type: Events.event_types\for_db event_type
    })

    -- Adds the new event to the timeline of every subscriber of @current_user
    do 
      user_followers = Followings\select "where object_type = ? and object_id = ? and type = ?", Followings\object_type_for_object(@current_user), @current_user.id, Followings.types.subscription
      preload user_followers, "source_user"

      for user in *user_followers
        follower_user = user.source_user

        TimelineEvents\create({
          user_id: follower_user.id
          event_id: event.id
        })
    
    -- If the event is a update, then every follower of the module should see the event
    if Events.event_types.update == Events.event_types\for_db(event_type)
      followers = Followings\select "where object_id = ? and object_type = ? and type = ?", event.object_id, event.object_type, Followings.types.subscription

      preload followers, "source_user"

      for users in *followers
        follower_user =  users.source_user
        TimelineEvents\create({
          user_id: follower_user.id
          event_id: event.id
        })

  remove_from_timeline: (object, event_type) =>
    db = require "lapis.db"
    timeline_events = if Events\object_type_for_object(object) == Events\object_type_for_model(Users)
      -- If we are removing the subscription from an use
      db.select "user_id, event_id from timeline_events join events on timeline_events.event_id = events.id and events.source_user_id = ?", object.id
    else 
      -- If we are removing the subscription from Module
      db.select "user_id, event_id from timeline_events join events on timeline_events.event_id = events.id and events.source_user_id = ? and events.object_type = ? and object_id = ?", object.user_id, Events\object_type_for_object(object), object.id

    for timeline_entry in *timeline_events
      TimelineEvents\delete(timeline_entry.user_id, timeline_entry.event_id)
