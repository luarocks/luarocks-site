
class AdminUser extends require "widgets.page"
  @include "widgets.table_helpers"
  @needs: {"user"}


  inner_content: =>
    h2 ->
      a href: @url_for(@user), @user\name_for_display!

    @field_table @user, {
      "id", "username", "slug", "email", "following_count", "updated_at",
      "created_at"
    }


    fieldset ->
      legend "Admin tools"
      form action: @url_for("admin.become_user"), method: "POST", ->
        input type: "hidden", name: "user_id", value: @user.id
        @csrf_input!
        button class: "button", "Become user"

