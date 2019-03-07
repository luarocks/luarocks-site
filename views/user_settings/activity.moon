import UserActivityLogs from require "models"

class UserSettingsSessions extends require "widgets.user_settings_page"
  @include "widgets.table_helpers"

  settings_content: =>
    p "On this page you can track account changing events and any other important security events associated with your account."

    if next @user_activity_logs
      @column_table @user_activity_logs, {
        {"created_at", label: "Date"}
        "ip"
        {"action", (log) ->
          code ->
            strong log.action
        }
        {"source", (log) ->
          code UserActivityLogs.sources\to_name log.source
        }
        {":summarize", label: "Details"}
        {"", (log) ->
          details ->
            summary "More"
            @field_table log, {
              "user_agent"
              "accept_lang"
            }
        }
      }
    else
      p class: "empty_message", ->
        em "Your account has no activity"
