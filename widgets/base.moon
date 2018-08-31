
import Widget from require "lapis.html"
import underscore from require "lapis.util"

class Base extends Widget
  @include "widgets.helpers"
  @include "widgets.icons"

  @widget_name: => underscore(@__name or "unknown") .. "_widget"

  -- classes chained from inheritance hierarchy
  @css_classes: =>
    return if @ == Base

    unless rawget @, "_css_classes"
      classes = @widget_name!
      if @__parent and @__parent.css_classes
        if parent_classes = @__parent\css_classes!
          classes ..= " #{parent_classes}"

      @_css_classes = classes

    @_css_classes

  content: =>
    element @enclosing_element_type or "div", class: @@css_classes!, ->
      @inner_content!

  widget_selector:  =>
    "'.#{@@widget_name!}'"

  render_modules: (modules, empty_text="No modules") =>
    unless next modules
      p class: "empty_message", "No modules"
      return

    widget require("widgets.module_list") :modules

  term_snippet: (cmd) =>
    pre class: "highlight lang_bash term_snippet", ->
      code ->
        span class: "nv", "$ "
        text cmd

  render_errors: =>
    if @errors
      div class: "errors", ->
        p "Errors:"
        ul ->
          for e in *@errors
            li e

  render_pager: (pager, current_page=@page) =>
    num_pages = pager\num_pages!
    return unless num_pages > 1

    page_url = (p) ->
      p == 1 and @req.parsed_url.path or "?page=#{p}"

    div class: "pager", ->
      if current_page > 1
        a href: page_url(current_page - 1), class: "prev_page button", "Prev"

      if current_page < num_pages
        a href: page_url(current_page + 1), class: "next_page button", "Next"

      span class: "pager_label", "Page #{current_page} of #{num_pages}"

  csrf_input: =>
    input type: "hidden", name: "csrf_token", value: @csrf_token

