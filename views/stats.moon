import to_json from require "lapis.util"

Header = require "widgets.stats_header"

class Stats extends require "widgets.page"
  @needs: {
    "cumulative_users"
    "cumulative_modules"
  }

  @es_module: [[
    import {StatsPage} from "stats";
    new StatsPage(widget_selector, widget_params);
  ]]

  js_init: =>
    super {
      graphs: {
        cumulative_users: @cumulative_users
        cumulative_modules: @cumulative_modules
        cumulative_versions: @cumulative_versions
      }
    }

  header_content: =>
    widget Header page_name: "global"

  inner_content: =>
    h3 "Cumulative modules"
    div id: "cumulative_modules", class: "graph_container"

    h3 "Cumulative versions"
    div id: "cumulative_versions", class: "graph_container"

    h3 "Cumulative registered accounts"
    div id: "cumulative_users", class: "graph_container"
