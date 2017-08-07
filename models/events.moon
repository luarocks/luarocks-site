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

  @create: (user, object, event_type) =>
    assert user, "missing event's user"
    assert object, "missing event's object"
    assert event_type, "missing event_type, events must have a type"

    opts = {
      :event_type
      source_user_id: user.id
      object_object_id: object.id
      object_object_type: @@object_type_for_object object
    }

    event = safe_insert @, opts

    return event

  delete: () =>
    db.delete @@table_name!, { id: @id }
