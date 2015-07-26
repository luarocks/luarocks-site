class Modules extends require "widgets.page"
  content: =>
    h2 ->
      text "All Modules"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @render_pager @pager
    @render_modules @modules
    @render_pager @pager


