import Widget from require "lapis.html"

require "moon"

class Module extends Widget
  content: =>
    h2 @module.name
    h3 class: "user", ->
      text @user.username

    div class: "description", ->
      text @module.description

    h3 "Versions"
    for v in *@versions
      div class: "version_row", ->
        url = "/modules/#{@user.slug}/#{@module.name}/#{v.version_name}"
        a href: url, v.version_name


    hr!
    pre moon.dump @user
    pre moon.dump @module
    pre moon.dump @current_version
