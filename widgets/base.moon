
import Widget from require "lapis.html"

class Base extends Widget
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
            }, mod.name

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

if ... == "test"
  print Base\format_number 1
  print Base\format_number 12
  print Base\format_number 123
  print Base\format_number 1233
  print Base\format_number 1233343434

Base
