
ModuleList = require "widgets.module_list"
config = require("lapis.config").get!

class UserSettingsImportToolbox extends require "widgets.user_settings_page"
  @needs: {"to_import"}

  settings_content: =>
    p "LuaRocks imported the functionalities of Lua Toolbox. Transfer your Lua
    Toolbox endorsements to LuaRocks to translate them into follows."

    p ->
      text "This tool matches your LuaRocks.org email address to your Lua
      Toolbox one. If they don't match and you need to import from a different
      address, "
      a href: "mailto:#{config.admin_email}", "send us an email"
      text "."

    has_import = if @to_import and next @to_import
      form method: "POST", class: "form", ->
        @render_errors!
        @csrf_input!
        div class: "button_row", ->
          input type: "submit", value: "Transfer endorsements to follows"

        p "The following modules will be followed:"
        widget ModuleList modules: @to_import
        true

    has_following = if @already_following
      h2 "You follow"
      p "You're following these modules that you've endorsed:"
      widget ModuleList modules: @already_following
      true


    unless has_import or has_following
      p ->
        text "There are no modules to import with your email: "
        strong @current_user.email

