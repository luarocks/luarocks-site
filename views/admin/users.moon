
class AdminUsers extends require "widgets.page"
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
    element "table", class: "table", ->
      thead ->
        tr ->
          td "User"
          td "Registered"
          td "Last active"
          td "Email"
          td "Followings"
          td "Modules"
          td ""

      for user in *@users
        tr ->
          td ->
            a href: @url_for(user), user\name_for_display!

          td -> @render_date user.created_at
          td -> user.last_active_at and @render_date user.last_active_at

          td user.email
          td @format_number user.following_count
          td @format_number user.modules_count

          td ->
            a href: @url_for("admin.user", id: user.id), "Admin"

    @render_pager @pager


