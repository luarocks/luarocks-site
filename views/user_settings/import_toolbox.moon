
class UserSettingsImportToolbox extends require "widgets.user_settings_page"

  settings_content: =>

    p ->
      text "LuaRocks imported the functionalities of Lua Toolbox."

    p ->
      text "Transfer your Lua Toolbox endorsements to LuaRocks to translate them into 
      followings and be notified when there are updates to your favorite modules. "

    p ->
      a href: @url_for("transfer_endorses", account), "Transfer endorsements"

