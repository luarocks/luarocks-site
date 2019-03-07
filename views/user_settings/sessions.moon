
import UserSessions from require "models"

types = {
  login_password: "Log in with password"
  register: "Registered account"
  update_password: "Changed password"
  login_github: "Log in with GitHub"
  register_github: "Register with GitHub"
}

class UserSettingsSessions extends require "widgets.user_settings_page"
  @include "widgets.table_helpers"

  settings_content: =>
    h2 "Sessions"
    p ->
      text "This page tracks website sessions for your account. You can disable
      a session to force a log out on for any programs using that session.
      Session logging was added March 2019, so legacy sessions are not
      available. "
      em "Last Active"
      text " times are updated every 15 minutes."

    @column_table @sessions, {
      "ip"
      {"Type", (session) ->
        name = UserSessions.types\to_name session.type
        if types[name]
          text types[name]
        else
          code name
      }
      {"last_active_at", label: "Last Active"}
      {"created_at", label: "Created"}
      {"user_agent", label: "User Agent"}
      {"accept_lang", label: "Accept Lang"}
      {"", (session) ->
        if session.id == @session.user.sid
          strong "Current Session"
          br!

        if session.revoked
          em ->
            text "Disabled"
            if session.revoked_at
              text " "
              @render_date session.revoked_at
        else
          form method: "post", ->
            @csrf_input!
            input type: "hidden", name: "session_id", value: session.id
            button class: "button", name: "action", value: "disable_session", "Disable"
      }
    }
