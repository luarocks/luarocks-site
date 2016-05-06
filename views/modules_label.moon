class ModulesLabel extends require "widgets.page"
  inner_content: =>
    h2 ->
      text @title
      text " "
      span class: "header_count", "(#{@pager and @pager\total_items! or 0})"

    if @pager
	    @render_pager @pager
	    @render_modules @modules
	    @render_pager @pager
	  else
	   	text "No modules"


