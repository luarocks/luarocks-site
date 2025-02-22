import to_json from require "lapis.util"

class Index extends require "widgets.page"
  @es_module: [[
    import {IndexPage} from "index";
    new IndexPage(widget_selector, widget_params);
  ]]

  js_init: =>
    super @downloads_daily

  header_content: =>
    div class: "intro_banner", ->
      div class: "intro_banner_inner", ->
        img src: "/static/logo.svg"

        div class: "intro_text", ->
          @raw_ssi "intro.html"

  inner_content: =>
    section class: "home_columns", ->
      div class: "column", ->
        div class: "split_header", ->
          h2 "Recent Modules"
          text " "
          span class: "header_sub", ->
            text "("
            a href: @url_for("manifest", manifest: "root"), "View all"
            text ") ("
            a href: @url_for("manifest_recent_versions", manifest: "root"), "Recent versions"
            text ")"

        @render_modules @recent_modules

      div class: "column", ->
        div class: "split_header", ->
          h2 "Most Downloaded"
          text " "
          span class: "header_sub", ->
            text "("
            a href: @url_for("popular_this_week"), "This week"
            text ")"

        @render_modules @popular_modules

    if next @labels
      section ->
        h2 ->
          text "View Modules by Labels"
        for i,l in ipairs @labels
          text ", " unless i == 1
          a href: @url_for("label",label: l.name), l.name

    section ->
      div class: "split_header", ->
        h2 "Daily Module Downloads"
        text " "
        span class: "header_sub", ->
          text "("
          a href: @url_for("stats"), "More graphs & stats"
          text ")"

      div id: "downloads_graph", class: "graph_container"

    section ->
      @raw_ssi "home.html"

