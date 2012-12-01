import Widget from require "lapis.html"

require "moon"

class Rocks extends Widget
  content: =>
    h2 "All Rocks"
    div class: "rock_list", ->
      for rock in *@rocks
        div class: "rock_row", ->
          a href: @url_for("rock", user: rock.user.slug, rock: rock.name), rock.name
          text " ("
          a href: @url_for("user_rocks", user: rock.user.slug), rock.user.username
          text ")"




