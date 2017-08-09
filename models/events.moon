db = require "lapis.db"

import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.models"

class Events extends Model
  @timestamp: true

  @event_types: enum {
    subscription: 1
    bookmark: 2
    update: 3
  }

  @relations: {
    {"source_user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
      [2]: {"user", "Users"}
    }}
  }

  @create: (opts={}) =>
    assert opts.user, "missing event's user"
    assert opts.object, "missing event's object"
    assert opts.event_type, "missing event_type, events must have a type"

    event_opts = {
      event_type: opts.event_type
      source_user_id: opts.user.id
      object_object_id: opts.object.id
      object_object_type: @@object_type_for_object opts.object
    }

    event = safe_insert @, event_opts

    return event

  delete: () =>
    db.delete @@table_name!, { id: @id }
