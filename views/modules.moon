class Modules extends require "widgets.base"
  content: =>
    h2 ->
      text "All Modules"
      text " "
      span class: "header_count", "(#{#@modules})"

    @render_modules @modules


