class Manifest extends require "widgets.base"
  content: =>
    h2 ->
      text @manifest\name_for_display!
      text " Manifest"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @term_snippet "luarocks install --server=#{@manifest\source_url @} <name>"

    @render_pager @pager

    @render_modules @modules, "No modules have been added yet"

    @render_pager @pager


