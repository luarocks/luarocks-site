
import Flow from require "lapis.flow"

import Followings, Notifications from require "models"

import assert_error from require "lapis.application"

class FollowingsFlow extends Flow
  expose_assigns: true

  new: (...) =>
    super ...
    assert_error @current_user, "must be logged in"

  follow_object: (object, kind) =>
    f = Followings\create {
      source_user_id: @current_user.id
      :object
      kind: kind
    }

    if f and object.get_user
      target_user = object\get_user!
      unless target_user.id == @current_user.id
        Notifications\notify_for target_user, object,
          Followings.kind\to_name(kind), @current_user

    f

  unfollow_object: (object, kind) =>
    following = Followings\find {
      source_user_id: @current_user.id
      object_type: Followings\object_type_for_object object
      object_id: object.id
      kind: kind
    }

    return unless following

    if object.get_user
      Notifications\undo_notify object\get_user!,
        object,
        Followings.kind\to_name(kind),
        @current_user

    following\delete!
