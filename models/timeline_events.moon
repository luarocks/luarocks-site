db = require "lapis.db"
import Model from require "lapis.db.model"
import Events, Followings, Users from require "models"

class TimelineEvents extends Model
  @primary_key: { "user_id", "event_id" }

  @create: (user, event) =>
    super {
      user_id: user.id
      event_id: event.id
    }

  @delete: (user, event) =>
    db.delete @table_name!, { user_id: user.id, event_id: event.id }

  @deliver: (user, event) =>
    switch event.event_type
      when Events.event_types.update
        followers = Followings\select "where object_id = ?", event.object_object_id

        for users in *followers
          follower_user = Users\find users.source_user_id
          @@create(follower_user, event)
      else
        @@create(user, event)

  @user_timeline: (user) =>
    @@select "where user_id = ?", user.id
