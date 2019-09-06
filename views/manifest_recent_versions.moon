ManifestHeader = require "widgets.manifest_header"

import time_ago_in_words from require "lapis.util"

class ManifestRecentVersions extends require "widgets.page"
  @needs: {
    "versions"
  }

  header_content: =>
    widget ManifestHeader page_name: "recent_versions"

  inner_content: =>
    unless next @versions
      p class: "empty_message", "There don't appear to be any rockspecs uploaded"

    @render_pager @pager

    li class: "version_list", ->
      for version in *@versions
        mod = version\get_module!
        user = mod\get_user!

        ul class: "version_row", ->
          a href: @url_for(mod), mod\name_for_display!
          text " "
          span class: "version_name", version.version_name

          if version.development
            span class: "development_flag", "dev"

          text " by "
          a class: "author", href: @url_for(user), user\name_for_display!

          text " "
          span class: "created_at", title: "#{version.created_at} UTC", time_ago_in_words(version.updated_at)

          if version.downloads > 0
            raw " &mdash; "
            span class: "downloads", @plural version.downloads, "download", "downloads"

    @render_pager @pager

