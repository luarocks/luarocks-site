ManifestHeader = require "widgets.manifest_header"

class Manifest extends require "widgets.page"
  content: =>
    widget ManifestHeader page_name: @development_only and "development_only" or "all", show_count: true

    if @development_only
      p ->
        text "This page lists modules in the manifest that contain
        development versions. See the complete list of modules on the main "
        a href: @url_for(@manifest), ->
          code @manifest.name
          text " manifest page"
        text "."

    @term_snippet "luarocks install --server=#{@manifest\source_url @, @development_only} <name>"

    if @manifest.description
      p @manifest.description

    @render_pager @pager

    @render_modules @modules, "No modules have been added yet"

    @render_pager @pager


