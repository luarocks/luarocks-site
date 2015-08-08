db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import upsert from require "helpers.models"

class Notifications extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"notification_objects", has_many: "NotificationObjects"}
    {"object", polymorphic_belongs_to: {
      [1]: {"user", "Users"}
      [2]: {"module", "Modules"}
      [3]: {"manifest", "Manifests"}
    }}
  }

  @types: enum {
    follow: 1
  }

  @valid_types_for_object_type: {
    module: enum { "follow" }
  }

  preloaders = {
  }

  @notify_for: (user, object, notify_type_name, target_object) =>
    return unless user
    assert object, "missing notification object"
    assert notify_type_name, "missing notification type"

    import NotificationObjects from require "models"

    notify_type = @types\for_db notify_type_name
    object_type = @object_type_for_object object
    object_type_name = @object_types\to_name(object_type)

    valid = @valid_types_for_object_type[object_type_name]
    unless valid[notify_type_name]
      error "notify type `#{notify_type_name}` not available for `#{object_type_name}`"

    action, notification = upsert @, {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      count: 1
      type: notify_type
    }, {
      count: db.raw "count + 1"
      updated_at: db.format_date!
    }, {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      type: notify_type
      seen: false
    }

    if target_object
      NotificationObjects\create_for_object notification.id, target_object

    action, notification

  @undo_notify: (user, object, notify_type_name, target_object) =>
    return unless user

    assert object, "missing notification object"
    assert notify_type_name, "missing notification type"

    import NotificationObjects from require "models"

    notify_type = @types\for_db notify_type_name
    object_type = @object_type_for_object object

    res = db.update @table_name!, {
      count: db.raw "count - 1"
    }, {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      type: notify_type
      seen: false
    }, "id", "count"

    action = nil

    if updated = unpack res
      action = "updated"

      -- delete it if count went to 0
      if updated.count <= 0
        action = "deleted"
        db.delete @table_name!, { id: updated.id }
        db.delete NotificationObjects\table_name!, { notification_id: updated.id }
      elseif target_object
        NotificationObjects\delete_for_object updated.id, target_object

    action

  @group_by_object_type: (notifications) =>
    groups = {}
    for n in *notifications
      group_name = @object_types\to_name n.object_type
      groups[group_name] or= {}
      table.insert groups[group_name], n

    groups

  @group_by_notification_type: (notifications) =>
    groups = {}
    for n in *notifications
      type_name = Notifications.types\to_name n.type
      groups[type_name] or= {}
      table.insert groups[type_name], n

    groups

  @preload_for_display: (notifications) =>
    @preload_objects notifications

    import Users, NotificationObjects from require "models"
    user_objects = [n.object for n in *notifications when n.object and n.object.user_id]
    Users\include_in user_objects, "user_id", fields: Users.fields_for_display

    groups = @group_by_object_type notifications
    for group_name, nots in pairs groups
      if preloader = preloaders[group_name]
        preloader @, nots, [n.object for n in *nots when n.object]

    NotificationObjects\preload_notifications notifications
    true

  get_associated_objects: =>
    nos = @get_notification_objects!
    [no\get_object! for no in *nos when no\get_object!]

  prefix: =>
    switch @type
      when @@types.follow
        "You got followed by"
      when @@types.join
        if @count == 1
          "Someone joined "
        else
          "#{@count} people joined "
      when @@types.submit
        nil
      else
        error "unknown notification type: #{@@types\to_name @type}"

  suffix: =>
    nil

  object_title: =>
    object = @get_object!
    title = if object.name_for_display
      object\name_for_display!
    else
      object.title or object.name

    (assert title, "failed to get title for notification")

  mark_seen: =>
    @update seen: true
