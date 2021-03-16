
class AdminUsers extends require "widgets.admin.page"
  @needs: {"users", "pager"}

  inner_content: =>
    h2 "Users"

    form class: "form", ->
      label ->
        text "Find by email"
        text " "
        input type: "text", name: "email", placeholder: "email"
        text " "
        button "Find"

    @render_pager @pager
    @column_table @users, {
      "id"
      {"user", value: (user) -> user}
      "flags"
      "created_at"
      "last_active_at"
      "email"
      "following_count"
      "followers_count"
      "modules_count"
      "stared_count"
    }
    @render_pager @pager


