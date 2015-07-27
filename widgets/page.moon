import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_name: => underscore(@__name or "unknown") .. "_page"

  @css_classes: =>
    return if @ == Page
    Page.__parent.css_classes @


  content: =>
    div class: "main_column", ->
      div class: @@css_classes!, ->
        @inner_content!

