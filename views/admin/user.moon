
class AdminUser extends require "widgets.page"
  @include "widgets.table_helpers"
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
      element "table", class: "table", ->
        thead ->
          tr ->
            td "Object"
            td "Created at"

        for f in *@followings
          obj = f\get_object!
          continue unless obj
          tr ->
            td ->
              a href: @url_for(obj), obj.title or obj.name

            td ->
              @render_date f.created_at

    fieldset ->
      legend "Admin tools"
      form action: @url_for("admin.become_user"), method: "POST", ->
        input type: "hidden", name: "user_id", value: @user.id
        @csrf_input!
        button class: "button", "Become user"

