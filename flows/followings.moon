
import Flow from require "lapis.flow"

import Followings from require "models"

import assert_error from require "lapis.application"

class FollowingsFlow extends Flow
  expose_assigns: true

  new: (...) =>
    super ...
    assert_error @current_user, "must be logged in"
  
  follow_object: (object) =>
    Followings\create {
      source_user_id: @current_user.id
      :object
    }

  unfollow_object: (object) =>
    following = Followings\find {
      source_user_id: @current_user.id
      object_type: Followings\object_type_for_object object
      object_id: object.id
    }

    return unless following
    following\delete!



