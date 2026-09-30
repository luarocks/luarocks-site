class Modules extends require "widgets.page"
  inner_content: =>
    h2 ->
      text "All Modules"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @render_pager @pager
    @render_modules @modules, "No modules", show_dates: true
    @render_pager @pager


