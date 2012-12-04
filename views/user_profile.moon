
class extends require "widgets.base"
  content: =>
    h2 ->
      text "#{@user.username}'s Modules"
      text " "
      span class: "header_count", "(#{#@modules})"

    @term_snippet "luarocks install --server=#{@user\source_url @} <name>"
    
    @render_modules @modules

