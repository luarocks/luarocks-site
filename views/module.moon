import Widget from require "lapis.html"

class Module extends Widget
  content: =>
    h2 @module.name

    h3 "Author"
    a href: @url_for("user_profile", user: @user.slug), @user.username

    h3 "About"
    div class: "description", ->
      text @module.description or @module.summary

    h3 "Versions"
    for v in *@versions
      div class: "version_row", ->
        url = "/modules/#{@user.slug}/#{@module.name}/#{v.version_name}"
        a href: url, v.version_name

    if next @manifests
      h3 "Manifests"
      for m in *@manifests
        div class: "manifest_row", ->
          a href: "TODO", ->
            code m.name


