import Widget from require "lapis.html"

require "moon"

class Rock extends Widget
  content: =>
    h2 @rock.name
    h3 class: "user", ->
      text @user.username

    div class: "description", ->
      text @rock.description

    h3 "Versions"
    for v in *@versions
      div class: "version_row", ->
        url = "/rocks/#{@user.slug}/#{@rock.name}/#{v.version_name}"
        a href: url, v.version_name


    hr!
    pre moon.dump @user
    pre moon.dump @rock
    pre moon.dump @current_version
