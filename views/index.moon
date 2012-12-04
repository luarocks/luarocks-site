
class Index extends require "widgets.base"
  -- @recent_modules, @popular_modules

  content: =>
    div class: "home_columns", ->
      div class: "column", ->
        h2 "Recent Modules"
        @render_modules @recent_modules

      div class: "column last", ->
        h2 "Popular Modules"
        @render_modules @popular_modules

    @raw_ssi "home.html"

