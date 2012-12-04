class Manifest extends require "widgets.base"
  content: =>
    h2 ->
      code @manifest.name
      text " Manifest"
      text " "
      span class: "header_count", "(#{#@modules})"

    @term_snippet "luarocks install --server=#{@manifest\source_url @} <name>"

    @render_modules @modules

