db = require "lapis.db"
import Model from require "lapis.db.model"


class TimelineEvents extends Model
  @primary_key: { "user_id", "event_id" }

  @create: (opts={}) =>
    assert opts.user_id, "user id not specified"
    assert opts.event_id, "event id not specified"

    super {
      user_id: opts.user_id
      event_id: opts.event_id
    }

  @delete: (user, event) =>
    db.delete @table_name!, { user_id: user.id, event_id: event.id }

  @deliver: (user, event) =>
    import Events, Followings, Users from require "models"

    switch event.event_type
      when Events.event_types.update
        followers = Followings\select "where object_id = ? and object_type = ?", event.object_object_id, event.object_object_type

        for users in *followers
          follower_user = Users\find users.source_user_id
          @@create({
            user_id: follower_user.id
            event_id: event
          })
      else
        @@create({
          user_id: user.id
          event_id: event.id
        })

        if Events\model_for_object_type(event.object_object_type) == Users
          @@create({
            user_id: Users\find(event.object_object_id).id
            event_id: event.id
          })

  @user_timeline: (user) =>
    @@select "where user_id = ?", user.id
