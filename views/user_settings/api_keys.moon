
class UserSettingsApiKeys extends require "widgets.user_settings_page"
  @include "widgets.table_helpers"

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

      @column_table @api_keys, {
        {"Comment (enter to save)", (key) ->
          form method: "post", class: "form", ->
            @csrf_input!
            input type: "hidden", name: "api_key", value: key.key
            input {
              type: "text"
              name: "comment"
              placeholder: "Optional"
              value: key.comment
            }
        }
        {"Key", (key) ->
          details ->
            summary ->
              code key.key\sub(1, 10) .. "…"

            input {
              type: "text"
              class: "rendered_key"
              readonly: true
              value: key.key
              onfocus: "this.select()"
            }
        }
        {"created_at", label: "Created at"}
        {"", (key) ->
          a href: @url_for("delete_api_key", :key), "Revoke..."
        }
      }

    form class: "form", method: "post", action: @url_for"new_api_key", ->
      @csrf_input!
      div class: "button_row", ->
        button "Generate New Key"


