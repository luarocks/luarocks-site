class Manifest extends require "widgets.base"
  content: =>
    h2 ->
      text @manifest\name_for_display!
      text " Manifest"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    div class: "page_tabs", ->
      a href: @url_for(@manifest), class: "tab #{@development_only and "" or "active"}", "All modules"
      a href: @url_for(@manifest, development_only: true), class: "tab #{@development_only and "active" or ""}", "Development only"

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


