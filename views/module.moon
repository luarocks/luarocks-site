import Widget from require "lapis.html"

class Module extends Widget
  content: =>
    h2 @module.name

    h3 "About"
    a href: @url_for("user_profile", user: @user.slug), @user.username

    div class: "description", ->
      text @module.description

    h3 "Versions"
    for v in *@versions
      div class: "version_row", ->
        url = "/modules/#{@user.slug}/#{@module.name}/#{v.version_name}"
        a href: url, v.version_name

