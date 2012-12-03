class Manifest extends require "widgets.base"
  content: =>
    h2 ->
      code @manifest.name
      text " Manifest"
      text " "
      span class: "header_count", "(#{#@modules})"

    pre class: "manifest_source", ->
      text "luarocks install --source=#{@manifest\source_url @} <name>"

    @render_modules @modules

