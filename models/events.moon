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
    {"source", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
      [2]: {"user", "Users"}
    }}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
      [2]: {"user", "Users"}
    }}
  }

  @create: (source, object, event_type) =>
    assert source, "missing event's source"
    assert object, "missing event's object"
    assert event_type, "missing event_type, events must have a type"

    opts = {
      :event_type
      source_object_id: source.id
      source_object_type: @@object_type_for_object source
      object_object_id: object.id
      object_object_type: @@object_type_for_object object
    }

    event = safe_insert @, opts

    return event

  delete: () =>
    db.delete @@table_name!, { id: @id }

  event_description: () =>
    switch @event_type
      when @@event_types.subscription
        "subs"
      when @@event_types.bookmark
        "book"
      when @@event_types.update
        "update"
      else
        ""
