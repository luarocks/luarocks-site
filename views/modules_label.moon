class Modules extends require "widgets.page"
  inner_content: =>
    h2 ->
      text @title
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @render_pager @pager
    @render_modules @modules
    @render_pager @pager


