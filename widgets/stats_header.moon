class ManifestHeader extends require "widgets.base"
  page_name: "global"

  inner_content: =>
    h2 "Luarocks.org stats"

    div class: "page_tabs", ->
      @render_tab "global", "Global stats", @url_for "stats"
      @render_tab "this_week", "Popular this week", @url_for "popular_this_week"

  render_tab: (name, label, href) =>
    a href: href, class: "tab #{name == @page_name and "active" or ""}", label
