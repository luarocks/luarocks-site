
Header = require "widgets.stats_header"

class PopularThisWeek extends require "widgets.page"
  @needs: {
    "top_versions"
    "top_new_versions"
  }

  render_tuples: (tuples) =>
    element "table", class: "table", ->
      thead ->
        tr ->
          td "Rank"
          td "Downloads"
          td "Module"

      for rank, {:sum, :version} in ipairs tuples
        mod = version\get_module!
        user = mod\get_user!

        tr ->
          td rank
          td ->
            text @format_number sum

          td ->
            a href: @url_for(mod), mod\name_for_display!
            text " "
            span class: "version_name", version.version_name

            if version.development
              span class: "development_flag", "dev"

            text " by "
            a class: "author sub", href: @url_for(user), user\name_for_display!

  inner_content: =>
    widget Header page_name: "this_week"

    h3 "Top Lua modules this week"
    p "Top downloaded versions in the past #{@days} days."
    @render_tuples @top_versions

    p "Top downloaded versions in the past #{@days} days excluding any that
    were in last week's top."
    @render_tuples @top_new_versions

