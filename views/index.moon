import to_json from require "lapis.util"

class Index extends require "widgets.page"
  content: =>
    div class: @@css_classes!, ->
      div class: "intro_banner", ->
        div class: "intro_banner_inner", ->
          img src: "/static/logo.svg"

          div class: "intro_text", ->
            @raw_ssi "intro.html"

      div class: "main_column", ->
        @inner_content!

  inner_content: =>
    div class: "home_columns", ->
      div class: "column", ->
        h2 ->
          text "Recent Modules"
          text " "
          span class: "header_sub", ->
            text "("
            a href: @url_for("manifest", manifest: "root"), "View all"
            text ") ("
            a href: @url_for("manifest_recent_versions", manifest: "root"), "Recent versions"
            text ")"

        @render_modules @recent_modules

      div class: "column last", ->
        h2 ->
          text "Most Downloaded"
          span class: "header_sub", ->
            text "("
            a href: @url_for("popular_this_week"), "This week"
            text ")"

        @render_modules @popular_modules

    if next @labels
      h2 ->
        text "View Modules by Labels"
      for i,l in ipairs @labels
        text ", " unless i == 1
        a href: @url_for("modules_label",label: l.name), l.name

    h2 ->
      text "Daily Module Downloads"
      span class: "header_sub", ->
        text "("
        a href: @url_for("stats"), "More graphs & stats"
        text ")"

    div id: "downloads_graph", class: "graph_container"

    @raw_ssi "home.html"

    @content_for "js_init", ->
      script type: "text/javascript", src: "/static/lib/jquery-2.1.1.min.js"
      script type: "text/javascript", src: "/static/lib/d3.min.js"
      script type: "text/javascript", src: "/static/main.js"

      script type: "text/javascript", ->
        raw "new M.Index(#{@widget_selector!}, #{to_json @downloads_daily});"

