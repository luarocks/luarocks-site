import Events, Modules, Users from require "models"
import time_ago_in_words from require "lapis.util"

class TimelineEvents extends require "widgets.base"
  @needs: {
    "modules"
  }

  inner_content: =>
    ul ->
      timeline = @current_user\timeline!

      for timeline_event in *timeline
        row_event = timeline_event.event
        user = timeline_event.user

        message = switch row_event.event_type
          when Events.event_types.subscription
            " followed "
          when Events.event_type.bookmark
            " starred "
          when Events.event_type.update
            " delivered a new version of "
          else
            ""
        li ->
          span class: "author", ->
            a href: @url_for("user_profile", user: user.slug), user\name_for_display!
            text message

            switch Events\model_for_object_type(row_event.object_type)
              when Modules
                module = row_event.object
                a {
                  class: "title",
                  href: @url_for("module", user: Users\find(module.user_id).slug, module: module.name)
                }, module\name_for_display!

                text " module"
              when Users
                usr = row_event.object
                a {
                  class: "title",
                  href: @url_for("user_profile", user: usr.slug)
                }, usr\name_for_display!
              else
                ""
            text " ", time_ago_in_words(row_event.created_at)
