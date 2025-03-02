
class ManifestHeader extends require "widgets.page_header"
  page_name: "all"

  admin_panel: =>

  inner_content: =>
    div class: "page_header_inner", ->
      h1 ->
        text @manifest\name_for_display!
        text " Manifest"
        if @show_count
          text " "
          span class: "sub", "(#{@format_number @pager\total_items!})"

    @admin_panel!

    div class: "page_tabs", ->
      @render_tab "all", "All modules", @url_for @manifest
      @render_tab "development_only", "Development modules", @url_for @manifest, development_only: true
      @render_tab "maintainers", "Maintainers", @url_for "manifest_maintainers", manifest: @manifest.name
      @render_tab "recent_versions", "Recent additions", @url_for "manifest_recent_versions", manifest: @manifest.name

  render_tab: (name, label, href) =>
    a href: href, class: "tab #{name == @page_name and "active" or ""}", label
