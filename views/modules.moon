import Widget from require "lapis.html"

require "moon"

class Modules extends Widget
  content: =>
    h2 ->
      text "All Modules"
      text " "
      span class: "rock_count", "(#{#@modules})"

    div class: "rock_list", ->
      for mod in *@modules
        div class: "rock_row", ->
          div class: "main", ->
            a {
              class: "title",
              href: @url_for("module", user: mod.user.slug, module: mod.name)
            }, mod.name

            span class: "author", ->
              text " ("
              a href: @url_for("user_modules", user: mod.user.slug), mod.user.username
              text ")"

          div class: "summary", ->
            text mod.summary




