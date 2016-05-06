
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
          text "1 endorsement imported with success."

      elseif @transfer_count > 1
        p ->
          text "#{@transfer_count} endorsements imported with success."

      else
         p ->
          text "No endorsements were imported."
    else
      form method: "POST", class: "form", ->
        @csrf_input!
        div class: "button_row", ->
          input type: "submit", value: "Transfer endorsements"


    

