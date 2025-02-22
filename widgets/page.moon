import underscore from require "lapis.util"

class BasePage extends require "widgets.base"
  @widget_class_name: =>
    if @ == BasePage
      return "base_page"
    else
      "#{@widget_name!}_page"

  content: =>
    main @widget_enclosing_attributes!, ->
      if @header_content
        @header_content!

      div class: "main_column", ->
        @inner_content!

    @render_js_init!
