import Widget from require "lapis.html"

class Layout extends Widget
  user_panel: =>
    div class: "user_panel", ->
      if @current_user
        span class: "login", @current_user.username
        raw " &middot; "
        a href: @url_for"upload_rockspec", "Upload Rock"
        raw " &middot; "
        a href: @url_for"user_logout", "Log Out"
      else
        a href: @url_for"user_login", "Log In"
        raw " &middot; "
        a href: @url_for"user_register", "Register"

  content: =>
    html_5 ->
      head ->
        title "MoonRocks"
        link rel: "stylesheet", href: "/static/style.css"
        script type: "text/javascript", src: "/static/main.js"

      body ->
        div class: "content", ->
          div class: "header", ->
            div class: "header_inner", ->
              @user_panel!
              h1 -> a href: @url_for"index", "MoonRocks"

          div class: "main_column", ->
            @content_for "inner"

        div class: "footer", ->
          a href: @url_for"modules", "Modules"


