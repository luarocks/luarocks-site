
class extends require "widgets.base"
  content: =>
    h2 ->
      text "#{@user.username}'s Modules"
      text " "
      span class: "header_count", "(#{#@modules})"


    pre class: "manifest_source", ->
      text "luarocks install --source=#{@user\source_url @} <name>"
    
    @render_modules @modules

