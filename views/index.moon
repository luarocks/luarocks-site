
class Index extends require "widgets.base"
  -- @recent_modules, @popular_modules

  content: =>
    div class: "home_columns", ->
      div class: "column", ->
        h2 ->
          text "Recent Modules"
          text " "
          span class: "header_sub", ->
            text "("
            a href: @url_for("manifest", manifest: "root"), "View all"
            text ")"
        @render_modules @recent_modules

      div class: "column last", ->
        h2 "Popular Modules"
        @render_modules @popular_modules

    @raw_ssi "home.html"

