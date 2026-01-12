
shapes = require "helpers.shapes"
import types from require "tableshape"

class ModuleList extends require "widgets.base"
  @prop_types: {
    modules: types.table
    show_manifests: shapes.default(false) * types.boolean
    show_dates: shapes.default(false) * types.boolean
  }

  widget_enclosing_element: "ul"

  inner_content: =>
    for mod in *@props.modules
      user = mod\get_user!

      li class: "module_row", ->
        div class: "main", ->
          a {
            class: "title",
            href: @url_for("module", user: user.slug, module: mod.name)
          }, mod\name_for_display!

          span class: "author", ->
            text " by "
            a href: @url_for("user_profile", user: user.slug), user\name_for_display!
            text ""

          span class: "downloads", ->
            raw " &mdash; "
            text " downloads: "
            span title: @format_number(mod.downloads), class: "value", @format_big_number mod.downloads

          if @props.show_manifests
            manifests = mod\get_manifests!
            if next manifests
              div class: "module_manifests", ->
                for manifest in *manifests
                  a href: @url_for(manifest), class: "manifest_tag", manifest\name_for_display!

          if @props.show_dates
            span class: "dates", ->
              date = require "date"
              span class: "created", title: date(mod.created_at)\fmt("${iso}Z"), ->
                text @format_short_age mod.created_at

              current_version = mod\get_current_version!
              if current_version
                span class: "updated", title: date(current_version.created_at)\fmt("${iso}Z"), ->
                  text " → "
                  text @format_short_age current_version.created_at

        div class: "summary", ->
          text mod.summary

