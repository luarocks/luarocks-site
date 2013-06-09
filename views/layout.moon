import Widget from require "lapis.html"

class Layout extends Widget
  user_panel: =>
    div class: "user_panel", ->
      if @current_user
        a href: @url_for("user_profile", user: @current_user), class: "login", @current_user.username
        raw " &middot; "
        a href: @url_for"upload_rockspec", "Upload Rockspec"
        raw " &middot; "
        a href: @url_for"user_settings", "Settings"
        raw " &middot; "
        a href: @url_for"user_logout", "Log Out"
      else
        a href: @url_for"user_login", "Log In"
        raw " &middot; "
        a href: @url_for"user_register", "Register"

  content: =>
    html_5 ->
      head ->
        meta charset: "utf-8"
        title ->
          if @title
            text "#{@title} - MoonRocks"
          else
            text "MoonRocks"

        if @page_description
          meta name: "description", content: @page_description

        link rel: "stylesheet", href: "/static/style.css?#{require "cache_buster"}"
        -- script type: "text/javascript", src: "/static/main.js"

        raw [[
          <script type="text/javascript">
            if (window.location.hostname != "localhost") {
              var _gaq = _gaq || [];
              _gaq.push(['_setAccount', 'UA-136625-8']);
              _gaq.push(['_trackPageview']);

              (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
              })();
            }
          </script>
        ]]


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
            raw " &middot; "
            a href: "https://github.com/leafo/moonrocks-site/issues", "Issues"

          a href: @url_for("index"), "Home"
          raw " &middot; "
          a href: @url_for("manifest", manifest: "root"), "Root Manifest"
          raw " &middot; "
          a href: @url_for"modules", "Modules"
          raw " &middot; "
          a href: @url_for"changes", "Changes"
          raw " &middot; "
          a href: @url_for"about", "About"


