TimelineEvents = require "widgets.timeline_events"
  
class Timeline extends require "widgets.page"
  inner_content: =>
    h2 ->
      text "Timeline"
    widget TimelineEvents!

