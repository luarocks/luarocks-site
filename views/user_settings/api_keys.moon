
class UserSettingsApiKeys extends require "widgets.user_settings_page"
  @needs: {
    "api_keys"
  }

  settings_content: =>
    p ->
      text "An API key is used to authenticate the "
      code "luarocks upload"
      text " command line tool to create and modify modules. Treat it like
      a password and don't share it with anyone."

    if #@api_keys == 0
      p "You currently don't have any keys."
    else
      element "table", class: "table", ->
        thead ->
          tr ->
            td ""
            td "Key"
            td "Created At"
            td ""

        for key in *@api_keys
          tr ->
            td ->
              form method: "post", class: "form", ->
                @csrf_input!
                input type: "hidden", name: "api_key", value: key.key
                input {
                  type: "text"
                  name: "comment"
                  placeholder: "Comment"
                  value: key.comment
                }

            td -> code key.key
            td key.created_at
            td ->
              a href: @url_for("delete_api_key", :key), "Revoke"

    form class: "form", method: "post", action: @url_for"new_api_key", ->
      @csrf_input!
      div class: "button_row", ->
        button "Generate New Key"


