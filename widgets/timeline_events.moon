import Events from require "models"
  
class TimelineEvents extends require "widgets.base"
  inner_content: =>
    ul ->
      for event in *@current_user\timeline!
        row_event = Events\find(event.user_id, event.event_id)
        li row_event\event_description!
