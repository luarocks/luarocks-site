
import Widget from require "lapis.html"
import underscore from require "lapis.util"

class Base extends Widget
  @include "widgets.helpers"
  @widget_name: => underscore @__name or "some_widget"

  content: =>
    div class: @widget_selector(false), ->
      @inner_content!

  widget_selector: (for_js=true) =>
    selector = "#{@@widget_name!}_page"
    if for_js
      "'.#{selector}'"
    else
      selector

  render_modules: (modules, empty_text="No modules") =>
    unless next modules
      p class: "empty_message", "No modules"
      return

    div class: "module_list", ->
      for mod in *modules
        div class: "module_row", ->
          div class: "main", ->
            a {
              class: "title",
              href: @url_for("module", user: mod.user.slug, module: mod.name)
            }, mod\name_for_display!

            span class: "author", ->
              text " by "
              a href: @url_for("user_profile", user: mod.user.slug), mod.user.username
              text ""

            span class: "downloads", ->
              raw " &mdash; "
              text " downloads: "
              span class: "value", @format_number mod.downloads

          div class: "summary", ->
            text mod.summary

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

