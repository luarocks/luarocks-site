
class ModuleVersion extends require "widgets.base"
  rock_url: (item) =>
    "/manifests/#{@user\url_key!}/#{item.rockspec_fname or item.rock_fname}"

  content: =>
    h2 "#{@module\name_for_display!} #{@version\name_for_display!}"
    @admin_panel!

    div ->
      text "Downloads: "
      span class: "value", @format_number @version.downloads


    h3 "Available Downloads"
    ul class: "rock_list", ->
      li class: "arch", ->
        a href: @rock_url(@version), "rockspec"

      for rock in *@rocks
        li class: "arch", ->
          a href: @rock_url(rock), rock.arch

    a href: @url_for("module", user: @user.slug, module: @module.name), "Back To Module"

  admin_panel: =>
    return unless @module\allowed_to_edit @current_user

    div class: "admin_tools", ->
      span class: "label", "Owner Tools: "
      a href: @url_for("upload_rock", @), "Upload Rock"
      raw " &middot; "
      a href: @url_for("delete_module_version", @), "Delete This Version"


