
class AdminUser extends require "widgets.admin.page"
  @needs: {"user", "followings", "user_manifest_admins", "user_data", "user_sessions", "api_keys", "activity_logs"}

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
      {":is_admin"}
      {":is_suspended"}
      {":is_spam"}
    }

    if @user_data
      h3 "Profile Data"
      @field_table @user_data, {
        {"email_verified", type: "boolean"}
        {"twitter", (d) -> if d.twitter then a href: d.twitter, target: "_blank", d\twitter_handle! else em "none"}
        {"website", (d) -> if d.website then a href: d.website, target: "_blank", d.website else em "none"}
        {"github", (d) -> if d.github then a href: d.github, target: "_blank", d\github_handle! else em "none"}
        {"profile", type: "collapse_pre"}
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
      {"object", (f) ->
        if object = f\get_object!
          @render_model object
        else
          code {
            title: f.object_type
          }, Followings.object_types\to_name f.object_type
          text " "
          code f.object_id
          text " "
          em "(deleted)"
      }
      {"object_type", Followings.object_types}
      {"type", Followings.types}
      "created_at"
    }

    h3 "User Sessions"
    import UserSessions from require "models"
    if @user_sessions and #@user_sessions > 0
      @column_table @user_sessions, {
        {"type", UserSessions.types}
        "ip"
        {"user_agent", type: "collapse_pre", truncate: 60}
        {"revoked", type: "boolean"}
        "last_active_at"
        "created_at"
      }
    else
      p class: "empty_table", "No sessions"

    h3 "API Keys"
    if @api_keys and #@api_keys > 0
      @column_table @api_keys, {
        {"key", (k) -> code k.key\sub(1, 12) .. "..."}
        "source"
        {"comment", type: "collapse_pre", truncate: 40}
        {"actions", label: "Usage"}
        {"revoked", type: "boolean"}
        "last_used_at"
        "created_at"
      }
    else
      p class: "empty_table", "No API keys"

    h3 "Recent Activity"
    import UserActivityLogs from require "models"
    if @activity_logs and #@activity_logs > 0
      @column_table @activity_logs, {
        {"action", (log) -> code log.action}
        {":summarize", label: "Details"}
        {"source", UserActivityLogs.sources}
        "ip"
        {":get_object", label: "Object"}
        "created_at"
      }
    else
      p class: "empty_table", "No activity logs"

    -- dangerous tools
    if @params.show_become_user
      fieldset ->
        legend "Admin tools"
        form action: @url_for("admin.become_user"), method: "POST", ->
          input type: "hidden", name: "user_id", value: @user.id
          @csrf_input!
          button class: "button", "Become user"
          label ->
            input type: "checkbox", required: true
            span " Confirm"




