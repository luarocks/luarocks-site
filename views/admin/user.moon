
class AdminUser extends require "widgets.page"
  @include "widgets.table_helpers"
  @needs: {"user"}


  inner_content: =>
    h2 @user\name_for_display!
    @field_table @user, {
      "id", "username", "slug", "email", "following_count", "updated_at",
      "created_at"
    }

