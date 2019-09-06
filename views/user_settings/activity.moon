import UserActivityLogs from require "models"

class UserSettingsSessions extends require "widgets.user_settings_page"
  @include "widgets.table_helpers"

  settings_content: =>
    p "On this page you can track account changing events and any other important security events associated with your account."

    if next @user_activity_logs
      @column_table @user_activity_logs, {
        {"created_at", label: "date"}
        {"ip", label: "IP address"}
        {"object", (log) ->
          object = log\get_object!

          if object and object.name_for_display
            title = "#{UserActivityLogs.object_types\to_name log.object_type}(#{log.object_id})"

            if object.url_params
              a {
                href: @url_for(object)
                :title
              }, object\name_for_display!
            else
              span {
                :title
              }, object\name_for_display!
          else
            span class: "sub", "n/a"
        }
        {"action", (log) ->
          code ->
            strong log.action
        }
        {"source", (log) ->
          code UserActivityLogs.sources\to_name log.source
        }
        {":summarize", label: "details"}
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
