
Header = require "widgets.stats_header"

class DependencyStats extends require "widgets.page"
  @needs: {
    "top_depended"
  }

  header_content: =>
    widget Header page_name: "dependencies"

  inner_content: =>
    h3 "Top depended upon modules"

    element "table", class: "table", ->
      thead ->
        tr ->
          td "Rank"
          td "Depended on count"
          td "Module"

      for rank, {:count, :manifest_module} in ipairs @top_depended
        mod = manifest_module\get_module!
        user = mod\get_user!

        tr ->
          td rank
          td @format_number count
          td ->
            a href: @url_for(mod), mod\name_for_display!
            text " by "
            a class: "author sub", href: @url_for(user), user\name_for_display!

