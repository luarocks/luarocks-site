import Events, Modules, Users from require "models"

class TimelineEvents extends require "widgets.base"
  @needs: {
    "modules"
  }

  inner_content: =>
    ul ->
      import preload from require "lapis.db.model"
      timeline = @current_user\timeline!
      preload timeline, event:  "object"
      preload timeline, "user"

      for event in *timeline
        row_event = event.event
        user = event.user

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

            switch Events\model_for_object_type(row_event.object_object_type)
              when Modules
                a {
                  class: "title",
                  href: @url_for("module", user: user.slug, module: row_event.object.name)
                }, mod\name_for_display!
              when Users
                a {
                  class: "title",
                  href: @url_for("user_profile", user: row_event.object.slug)
                }, usr\name_for_display!
              else
                ""
