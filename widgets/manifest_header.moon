
class ManifestHeader extends require "widgets.base"
  page_name: "all"

  inner_content: =>
    h2 ->
      text @manifest\name_for_display!
      text " Manifest"
      if @show_count
        text " "
        span class: "header_count", "(#{@pager\total_items!})"

    div class: "page_tabs", ->
      @render_tab "all", "All modules", @url_for @manifest
      @render_tab "development_only", "Development modules", @url_for @manifest, development_only: true
      @render_tab "maintainers", "Manifest maintainers", @url_for "manifest_maintainers", manifest: @manifest.name

  render_tab: (name, label, href) =>
    a href: href, class: "tab #{name == @page_name and "active" or ""}", label
