class ModuleList extends require "widgets.base"
  @needs: {
    "modules"
  }

  widget_enclosing_element: "ul"

  inner_content: =>
    for mod in *@modules
      user = mod\get_user!

      li class: "module_row", ->
        div class: "main", ->
          a {
            class: "title",
            href: @url_for("module", user: user.slug, module: mod.name)
          }, mod\name_for_display!

          span class: "author", ->
            text " by "
            a href: @url_for("user_profile", user: user.slug), user\name_for_display!
            text ""

          span class: "downloads", ->
            raw " &mdash; "
            text " downloads: "
            span title: @format_number(mod.downloads), class: "value", @format_big_number mod.downloads

        div class: "summary", ->
          text mod.summary

