db = require "lapis.db"
import Model from require "lapis.db.model"


class TimelineEvents extends Model
  @primary_key: { "user_id", "event_id" }

  @relations: {
    {"user", belongs_to: "Users"}
    {"event", belongs_to: "Events"}
  }

  @create: (opts={}) =>
    assert opts.user_id, "user id not specified"
    assert opts.event_id, "event id not specified"

    super {
      user_id: opts.user_id
      event_id: opts.event_id
    }

  @delete: (user, event) =>
    db.delete @table_name!, { user_id: user.id, event_id: event.id }

  @user_timeline: (user) =>
    import preload from require "lapis.db.model"
    timeline = @@select "where user_id = ? limit 50", user.id
    preload timeline, "user"
    preload timeline, event: "object"
    return timeline
