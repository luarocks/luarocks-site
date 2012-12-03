import Widget from require "lapis.html"

class Module extends Widget
  content: =>
    h2 @module.name
    @admin_panel!

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

    can_edit = @module\allowed_to_edit @current_user
    if next @manifests
      h3 "Manifests"
      for m in *@manifests
        @manifest = m
        div class: "manifest_row", ->
          a href: @url_for("manifest", @), ->
            code m.name

          if can_edit
            text " ("
            a href: @url_for("remove_from_manifest", @), "remove"
            text ")"

        @manifest = nil

  admin_panel: =>
    return unless @module\allowed_to_edit @current_user
    div class: "admin_tools", ->
      span class: "label", "Admin: "
      a href: @url_for("add_to_manifest", @), "Add To Manifest"

