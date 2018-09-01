PageHeader = require "widgets.page_header"

class Label extends require "widgets.page"
  header_content: =>
    widget PageHeader {
      inner_content: ->
        h1 ->
          text @title
          text " "
          span class: "sub", "(#{@pager and @pager\total_items! or 0})"
    }

  inner_content: =>
    if @show_non_root
      p ->
        text "Showing all modules. "
        a href: @url_for("label", label: @params.label),
          "Show modules in root manifest only"
    else
      p ->
        text "Showing only modules in the root manifest. "
        a href: @url_for("label", { label: @params.label }, non_root: "on"),
          "Show all modules"

    if @pager
      @render_pager @pager
      @render_modules @modules
      @render_pager @pager
    else
      text "No modules"


