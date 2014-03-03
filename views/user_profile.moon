
class extends require "widgets.base"
  content: =>
    h2 ->
      text "#{@user.username}'s Modules"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @term_snippet "luarocks install --server=#{@user\source_url @} <name>"
    
    @render_pager @pager
    @render_modules @modules
    @render_pager @pager

