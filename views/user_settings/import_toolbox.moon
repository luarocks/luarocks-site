
class UserSettingsImportToolbox extends require "widgets.user_settings_page"

  settings_content: =>

    p ->
      text "LuaRocks imported the functionalities of Lua Toolbox."

    p ->
      text "Transfer your Lua Toolbox endorsements to LuaRocks to translate them into 
      followings and be notified when there are updates to your favorite modules. "

    if @transfer
      if @transfer_count == 1
        p ->
          text "1 endorsement transfered with success."

      elseif @transfer_count > 1
        p ->
          text "#{@transfer_count} endorsements transfered with success."

      else
         p ->
          test "No endorsements were transfered."
    else
      p ->
        a href: @url_for("transfer_endorses", account), "Transfer endorsements"


    

