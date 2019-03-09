
class UserSettingsApiKeys extends require "widgets.user_settings_page"
  @include "widgets.table_helpers"

  @needs: {
    "api_keys"
  }

  settings_content: =>
    if @show_revoked
      p ->
        text "Revoked API keys are no longer able to be used. "
        a href: @url_for("user_settings.api_keys"), "Return to active API keys"
    else
      p ->
        text "An API key is used to authenticate the "
        code "luarocks upload"
        text " command line tool to create and modify modules. Treat it like
        a password and don't share it with anyone. ("
        a href: "?revoked", "View revoked API keys"
        text ")"

    if #@api_keys == 0
      if @show_revoked
        p "You don't have any revoked API keys."
      else
        p "You currently don't have any keys."
    else

      @column_table @api_keys, {
        {"Comment#{@show_revoked and "" or " (enter to save)"}", (key) ->
          if key.revoked
            text key.comment or -> em "n/a"
          else
            form method: "post", class: "form", ->
              @csrf_input!
              input type: "hidden", name: "api_key", value: key.key
              input {
                type: "text"
                name: "comment"
                placeholder: "no comment"
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
        {"last_used_at", label: "Last used"}
        {"", (key) ->
          if key.revoked
            strong "Revoked"
            if key.revoked_at
              text " "
              @render_date key.revoked_at
          else
            a href: @url_for("delete_api_key", :key), "Revoke..."
        }
      }

    form class: "form", method: "post", action: @url_for"new_api_key", ->
      @csrf_input!
      div class: "button_row", ->
        button "Generate New Key"


