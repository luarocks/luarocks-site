import to_json from require "lapis.util"

Header = require "widgets.stats_header"

class Stats extends require "widgets.page"
  @needs: {
    "cumulative_users"
    "cumulative_modules"
  }

  js_init: =>
    data = {
      graphs: {
        cumulative_users: @cumulative_users
        cumulative_modules: @cumulative_modules
        cumulative_versions: @cumulative_versions
      }
    }

    "M.Stats(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    widget Header page_name: "global"

    h3 "Cumulative modules"
    div id: "cumulative_modules", class: "graph_container"

    h3 "Cumulative versions"
    div id: "cumulative_versions", class: "graph_container"

    h3 "Cumulative registered accounts"
    div id: "cumulative_users", class: "graph_container"

    @content_for "js_init", ->
      script type: "text/javascript", src: "/static/lib/jquery-2.1.1.min.js"
      script type: "text/javascript", src: "/static/lib/d3.min.js"
      script type: "text/javascript", src: "/static/main.js"

      script type: "text/javascript", ->
        raw @js_init!

