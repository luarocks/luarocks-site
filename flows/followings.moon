
import Flow from require "lapis.flow"

import Followings, Notifications from require "models"

import assert_error from require "lapis.application"

class FollowingsFlow extends Flow
  expose_assigns: true

  new: (...) =>
    super ...
    assert_error @current_user, "must be logged in"

  follow_object: (object, kind) =>
    is_starring = if kind == "star"
      true
    else
      false

    f = Followings\create {
      source_user_id: @current_user.id
      :object
      :is_starring
    }

    if f and object.get_user
      target_user = object\get_user!
      unless target_user.id == @current_user.id
        Notifications\notify_for target_user, object,
          kind, @current_user

    f

  unfollow_object: (object, kind) =>
    is_starring = if kind == "star"
      true
    else
      false

    following = Followings\find {
      source_user_id: @current_user.id
      object_type: Followings\object_type_for_object object
      object_id: object.id
      :is_starring
    }

    return unless following

    if object.get_user
      Notifications\undo_notify object\get_user!,
        object,
        kind,
        @current_user

    following\delete(is_starring)
