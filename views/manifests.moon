
class Manifests extends require "widgets.base"
  inner_content: =>
    h2 ->
      text "All Manifests"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @render_pager @pager

    if next @manifests
      div class: "manifest_list", ->
        for manifest in *@manifests
          @render_manifest manifest
    else
      p class: "empty_message", "No modules"

  render_manifest: (manifest) =>
    div class: "manifest_row", ->
      div class: "main", ->
        a {
          class: "title",
          href: @url_for(manifest)
        }, manifest\name_for_display!

        span class: "downloads", ->
          raw " &mdash; "
          text " modules: "
          span class: "value", @format_number manifest.modules_count

        if manifest.is_open
          div class: "open_flag", title: "Anyone can submit to this manifest", "Open"

