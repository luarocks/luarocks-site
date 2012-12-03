
class ModuleVersion extends require "widgets.base"
  content: =>
    h2 "#{@module.name} #{@version.version_name}"
    @admin_panel!

    div ->
      text "Downloads: "
      span class: "value", @format_number @version.downloads

    div class: "rock_list", ->

    a href: @url_for("module", user: @user.slug, module: @module.name), "Back To Module"

  admin_panel: =>
    return unless @module\user_can_edit @current_user

    div class: "admin_tools", ->
      span class: "label", "Admin: "

      url = @url_for "upload_rock", {
        user: @user.slug,
        module: @module.name
        version: @version.version_name
      }

      a href: url, "Upload Rock"


