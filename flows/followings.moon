
import Flow from require "lapis.flow"

import Events, Followings, Notifications, TimelineEvents, Users from require "models"

import assert_error from require "lapis.application"

class FollowingsFlow extends Flow
  expose_assigns: true

  new: (...) =>
    super ...
    assert_error @current_user, "must be logged in"

    follow_object: (object, type) =>

    f = Followings\create {
      source_user_id: @current_user.id
      :object
      :type
    }

    if f and object.get_user
      target_user = object\get_user!
      unless target_user.id == @current_user.id
        Notifications\notify_for target_user, object,
          type, @current_user

    event = Events\create(@current_user, object, Events.event_types.subscription)
    TimelineEvents\deliver(@current_user, event)

    f

  unfollow_object: (object, type) =>
    following = Followings\find {
      source_user_id: @current_user.id
      object_type: Followings\object_type_for_object object
      object_id: object.id
      type: Followings.types\for_db type
    }

    event = Events\find {
      source_user_id: @current_user.id
      object_object_id: object.id
      object_object_type: Events\object_type_for_object object
      event_type: Events.event_types.subscription
    }

    return unless following

    if object.get_user
      Notifications\undo_notify object\get_user!,
        object,
        type,
        @current_user

    following\delete!
