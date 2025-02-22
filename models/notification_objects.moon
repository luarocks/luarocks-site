db = require "lapis.db"
import Model from require "lapis.db.model"

import safe_insert from require "helpers.models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE notification_objects (
--   notification_id integer NOT NULL,
--   object_type smallint NOT NULL,
--   object_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY notification_objects
--   ADD CONSTRAINT notification_objects_pkey PRIMARY KEY (notification_id, object_type, object_id);
-- ALTER TABLE ONLY notification_objects
--   ADD CONSTRAINT notification_objects_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;
--
class NotificationObjects extends Model
  @timestamp: true
  @primary_key: {"notification_id", "object_type", "object_type"}

  @relations: {
    {"object", polymorphic_belongs_to: {
      [1]: {"user", "Users"}
    }}
  }

  preloaders = {
  }

  @preload_notifications: (notifications) =>
    @include_in notifications, "notification_id", {
      flip: true
      many: true
    }

    nos = {}
    for n in *notifications
      continue unless n.notification_objects
      for no in *n.notification_objects
        table.insert nos, no

    @preload_objects nos

    grouped_by_object_type = {}
    for no in *nos
      object_type_name = @object_types[no.object_type]
      grouped_by_object_type[object_type_name] or= {}
      table.insert grouped_by_object_type[object_type_name], no

    for group_name, group in pairs grouped_by_object_type
      if preload = preloaders[group_name]
        preload @, group, [no.object for no in *nos when no.object]

    true

  @create_for_object: (notification_id, object) =>
    @create {
      object_type: @object_type_for_object object
      object_id: object.id
      :notification_id
    }

  @delete_for_object: (notification_id, object) =>
    db.delete NotificationObjects\table_name!, {
      object_type: @object_type_for_object object
      object_id: object.id
      notification_id: notification_id
    }

  @create: (opts={}) =>
    opts.object_type = @object_types\for_db opts.object_type
    safe_insert @, opts

