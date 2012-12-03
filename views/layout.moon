import Widget from require "lapis.html"

class Layout extends Widget
  user_panel: =>
    div class: "user_panel", ->
      if @current_user
        a href: @url_for("user_profile", user: @current_user), class: "login", @current_user.username
        raw " &middot; "
        a href: @url_for"upload_rockspec", "Upload Rockspec"
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
          div class: "right", ->
            text "by "
            a href: "http://twitter.com/moonscript", "@moonscript"
            raw " &middot; "
            a href: "http://github.com/leafo/moonrocks-site", "Source"

          a href: @url_for("index"), "Home"
          raw " &middot; "
          a href: @url_for("manifest", manifest: "root"), "Root Manifest"
          raw " &middot; "
          a href: @url_for"modules", "Modules"
          raw " &middot; "
          a href: @url_for"about", "About"


