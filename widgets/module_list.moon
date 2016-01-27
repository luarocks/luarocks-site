class ModuleList extends require "widgets.base"
  @needs: {
    "modules"
  }

  inner_content: =>
    for mod in *@modules
      user = mod\get_user!

      div class: "module_row", ->
        div class: "main", ->
          a {
            class: "title",
            href: @url_for("module", user: user.slug, module: mod.name)
          }, mod\name_for_display!

          span class: "author", ->
            text " by "
            a href: @url_for("user_profile", user: user.slug), user.username
            text ""

          span class: "downloads", ->
            raw " &mdash; "
            text " downloads: "
            span class: "value", @format_number mod.downloads

        div class: "summary", ->
          text mod.summary

