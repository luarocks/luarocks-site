
import Widget from require "lapis.html"
import underscore from require "lapis.util"

class Base extends Widget
  @widget_name: => underscore @__name or "some_widget"

  content: =>
    div class: "#{@@widget_name!}_page", ->
      @inner_content!

  render_modules: (modules, opts={}) =>
    unless next modules
      div class: "empty_message", "No Modules"
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


  format_number: (num) =>
    tostring(num)\reverse!\gsub("(...)", "%1,")\match("^(.-),?$")\reverse!

  truncate: (str, length) =>
    return str if #str <= length
    str\sub(1, length) .. "..."

  format_bytes: do
    limits = {
      {"gb", 1024^3}
      {"mb", 1024^2}
      {"kb", 1024}
    }

    (bytes) =>
      bytes = math.floor bytes
      suffix = " bytes"
      for {label, min} in *limits
        if bytes >= min
          bytes = math.floor bytes / min
          suffix = label
          break

      @format_number(bytes) .. suffix

  raw_ssi: (fname) =>
    res = ngx.location.capture "/static/site/www/#{fname}"
    error "Failed to include SSI `#{fname}`" unless res.status == 200
    raw res.body

  term_snippet: (cmd) =>
    pre class: "highlight lang_bash term_snippet", ->
      code ->
        span class: "nv", "$ "
        text cmd

  render_errors: =>
    if @errors
      div "Errors:"
      ul ->
        for e in *@errors
          li e

if ... == "test"
  print Base\format_number 1
  print Base\format_number 12
  print Base\format_number 123
  print Base\format_number 1233
  print Base\format_number 1233343434

Base
