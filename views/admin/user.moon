
class AdminUser extends require "widgets.admin.page"
  @needs: {"user", "followings", "user_manifest_admins"}

  inner_content: =>
    h2 ->
      a href: @url_for(@user), @user\name_for_display!

    @field_table @user, {
      "id",
      "username"
      "slug"
      "display_name"
      "email"
      "updated_at"
      "created_at"
      "last_active_at"
      "stared_count"
      "followers_count"
      "following_count"
      {"modules_count", ->
        a href: @url_for("admin.modules", nil, user_id: @user.id),
          @format_table_value_by_type "number", {}, @user.modules_count
      }
    }

    h3 "GitHub Accounts"
    github_accounts = @user\get_github_accounts!
    if github_accounts and #github_accounts > 0
      @column_table github_accounts, {
        {"github_login", label: "Login", (account) -> a href: account\profile_url!, target: "_blank", account.github_login}
        {"github_user_id", label: "User ID"}
        "created_at"
        "updated_at"
      }
    else
      p class: "empty_table", "No connected GitHub accounts"

    if @user_manifest_admins and #@user_manifest_admins > 0
      h3 "Manifest Admin For"
      @column_table @user_manifest_admins, {
        {"Manifest", (ma) ->
          manifest = ma\get_manifest!
          a href: @url_for(manifest), manifest.name}
        {"is_owner", label: "Owner"}
        "created_at"
      }

    h3 "Followings"
    import Followings from require "models"
    @column_table @user\get_follows!, {
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

