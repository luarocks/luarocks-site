
class ModuleVersion extends require "widgets.base"
  content: =>
    h2 "#{@module.name} #{@version.version_name}"

    div ->
      text "Downloads: "
      span class: "value", @format_number @version.downloads

    a href: @url_for("module", user: @user.slug, module: @module.name), "Back To Module"


