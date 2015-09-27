
class AdminUsers extends require "widgets.page"
  @needs: {"users", "pager"}

  inner_content: =>
    h2 "Users"

    @render_pager @pager
    element "table", class: "table", ->
      thead ->
        tr ->
          td "User"
          td "Registered"
          td "Email"
          td "Followings"
          td ""

      for user in *@users
        tr ->
          td ->
            a href: @url_for(user), user\name_for_display!

          td ->
            @render_date user.created_at

          td user.email
          td @format_number user.following_count

          td ->
            a href: "", "Admin"

    @render_pager @pager


