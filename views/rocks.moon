import Widget from require "lapis.html"

require "moon"

class Rocks extends Widget
  content: =>
    h2 ->
      text "All Rocks"
      text " "
      span class: "rock_count", "(#{#@rocks})"

    div class: "rock_list", ->
      for rock in *@rocks
        div class: "rock_row", ->
          div class: "main", ->
            a {
              class: "title",
              href: @url_for("rock", user: rock.user.slug, rock: rock.name)
            }, rock.name

            span class: "author", ->
              text " ("
              a href: @url_for("user_rocks", user: rock.user.slug), rock.user.username
              text ")"

          div class: "summary", ->
            text rock.summary




