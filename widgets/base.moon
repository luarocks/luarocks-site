
import Widget from require "lapis.html"
import underscore, encode_query_string from require "lapis.util"

class Base extends require "lapis.eswidget"
  @asset_packages: {"main"}

  @include "widgets.helpers"
  @include "widgets.icons"
  @include "widgets.table_helpers"

  render_modules: (modules, empty_text="No modules", opts) =>
    unless next modules
      p class: "empty_message", "No modules"
      return

    params = {
      :modules
    }

    if opts
      for k, v in pairs opts
        params[k] = v

    widget require("widgets.module_list") params

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

    default_params = {k,v for k,v in pairs @GET}

    page_url = (p) ->
      default_params.page = if p == 1 then nil else p
      "?" .. encode_query_string default_params

    div class: "pager", ->
      if current_page > 1
        a href: page_url(current_page - 1), class: "prev_page button", "Prev"

      if current_page < num_pages
        a href: page_url(current_page + 1), class: "next_page button", "Next"

      span class: "pager_label", "Page #{current_page} of #{num_pages}"

  csrf_input: =>
    input type: "hidden", name: "csrf_token", value: @csrf_token

