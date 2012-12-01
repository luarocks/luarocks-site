import Widget from require "lapis.html"

require "moon"

class Rock extends Widget
  content: =>
    h2 @rock.name
    h3 class: "user", ->
      text @user.username

    div class: "description", ->
      text @rock.description

    hr!
    pre moon.dump @user
    pre moon.dump @rock
