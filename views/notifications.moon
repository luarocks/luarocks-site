models = require "models"

import time_ago_in_words from require "lapis.util"

class Notifications extends require "widgets.page"
  @needs: {
    "seen_notifications"
    "unseen_notifications"
  }

  inner_content: =>
    h2 "Notifications"

    if next @unseen_notifications
      div class: "unseen_notifications", ->
        @render_notifications @unseen_notifications, true

    if next @seen_notifications
      div class: "seen_notifications", ->
        h3 "Old notifications"
        @render_notifications @seen_notifications

    if not next(@unseen_notifications) and not next(@seen_notifications)
      p class: "empty_message", "You haven't gotten any notifications yet."


  render_notifications: (nots, unseen) =>
    div class: "notification_list", ->
      for i, notification in ipairs nots
        object = notification.object
        continue unless object

        div class: "notification_row", ->
          if unseen
            span class: "new_tag", "New"

          text notification\prefix!
          text " "
          a href: @url_for(object), notification\object_title!
          text " "
          text notification\suffix!


          switch models.Notifications.types[notification.type]
            when "follow"
              users = notification\get_associated_objects!
              raw " &mdash; " if users[1]

              for i, user in ipairs users
                if i > 1
                  text ", "
                a href: @url_for(user), user\name_for_display!

          text " "
          span {
            class: "timestamp"
            title: "#{notification.created_at} UTC"
            time_ago_in_words notification.created_at
          }


