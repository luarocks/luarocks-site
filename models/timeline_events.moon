db = require "lapis.db"
import Model from require "lapis.db.model"
import Events from require "models"

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
      when Events.event_types.subscription
        @@create(user, event)
      when Events.event_types.bookmark
        @@create(@current_user, event)
      when Events.event_types.update
        ""
      else
        ""

  @user_timeline: (user) =>
    @@select "where user_id = ?", user.id
