import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_name: => underscore(@__name or "unknown") .. "_page"

  @css_classes: =>
    return if @ == Page
    Page.__parent.css_classes @

  content: =>
    main class: @@css_classes!, ->
      if @header_content
        @header_content!

      div class: "main_column", ->
        @inner_content!

