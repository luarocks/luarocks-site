import Widget from require "lapis.html"

cache_buster = require "helpers.cache_buster"

class Layout extends Widget
  @include "widgets.helpers"

  user_panel: =>
    div class: "user_panel", ->
      a href: "https://github.com/keplerproject/luarocks/wiki/Download", "Install"
      raw " &middot; "
      a href: "https://github.com/keplerproject/luarocks/wiki/Documentation", "Docs"
      raw " &middot; "

      if @current_user
        a href: @url_for("user_profile", user: @current_user), class: "login", -> b @current_user.username
        raw " &middot; "
        a href: @url_for"upload_rockspec", "Upload"
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
            text "#{@title} - LuaRocks"
          else
            text "LuaRocks"

        link href: "http://fonts.googleapis.com/css?family=Open+Sans:400italic,400,700", rel: "stylesheet", type: "text/css"

        if @page_description
          meta name: "description", content: @page_description

        link rel: "stylesheet", href: "/static/style.css?#{cache_buster}"

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
              div class: "logo", ->
                a href: @url_for"index", ->
                  if @current_user
                    img class: "icon_logo", alt: "LuaRocks", src: "/static/header_luarocks_icon.svg"
                  else
                    img class: "text_logo", alt: "LuaRocks", src: "/static/header_luarocks_name.svg"

              form class: "header_search", action: @url_for("search"), method: "GET", ->
                input type: "text", name: "q", placeholder: "Search modules or uploaders...", value: @params.q

          if @show_intro_banner
            div class: "intro_banner", ->
              div class: "intro_banner_inner", ->
                img src: "/static/logo.svg"

                div class: "intro_text", ->
                  @raw_ssi "intro.html"

          div class: "main_column", ->
            @content_for "inner"

        div class: "footer", ->
          div class: "right", ->
            a href: "http://twitter.com/moonscript", "@moonscript"
            raw " &middot; "
            revision = require "revision"
            a href: "https://github.com/leafo/moonrocks-site/commit/#{revision}", rel: "nofollow", revision
            raw " &middot; "
            a href: "http://github.com/leafo/moonrocks-site", "Source"
            raw " &middot; "
            a href: "https://github.com/leafo/moonrocks-site/issues", "Issues"

          a href: @url_for("index"), "Home"
          raw " &middot; "
          a href: @url_for"search", "Search"
          raw " &middot; "
          a href: @url_for("manifest", manifest: "root"), "Root Manifest"
          raw " &middot; "
          a href: @url_for"manifests", "Manifests"
          raw " &middot; "
          a href: @url_for"modules", "Modules"
          raw " &middot; "
          a href: @url_for"changes", "Changes"
          raw " &middot; "
          a href: @url_for"about", "About"

      @content_for "js_init"

