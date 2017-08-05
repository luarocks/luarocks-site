import Events, Modules, Users from require "models"

class TimelineEvents extends require "widgets.base"
  @needs: {
    "modules"
  }

  inner_content: =>
    ul ->
      for event in *@current_user\timeline!
        row_event = Events\find(event.event_id)
        user = Users\find(row_event.source_user_id)


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
                mod = Modules\find row_event.object_object_id
                a {
                  class: "title",
                  href: @url_for("module", user: user.slug, module: mod.name)
                }, mod\name_for_display!
              when Users
                usr = Users\find row_event.object_object_id
                a {
                  class: "title",
                  href: @url_for("user_profile", user: usr.slug)
                }, usr\name_for_display!
              else
                ""
