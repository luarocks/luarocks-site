import to_json_array from require "helpers.app"

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
        cumulative_users: to_json_array @cumulative_users
        cumulative_modules: to_json_array @cumulative_modules
        cumulative_versions: to_json_array @cumulative_versions
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
