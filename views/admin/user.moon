
class AdminUser extends require "widgets.admin.page"
  @needs: {"user", "followings"}

  inner_content: =>
    h2 ->
      a href: @url_for(@user), @user\name_for_display!

    @field_table @user, {
      "id", "username", "slug", "email", "following_count", "updated_at",
      "created_at", "last_active_at"
    }

    if next @followings
      h3 "Followings"
      import Followings from require "models"
      @column_table @followings, {
        {":get_object", label: "user"}
        {"object_type", Followings.object_types}
        "created_at"
      }

    fieldset ->
      legend "Admin tools"
      form action: @url_for("admin.become_user"), method: "POST", ->
        input type: "hidden", name: "user_id", value: @user.id
        @csrf_input!
        button class: "button", "Become user"

