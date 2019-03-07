Header = require "widgets.module_header"

diff = require "helpers.diff_match_patch"

match_lines = do
  import P, C, Ct from require "lpeg"
  newline = P"\r\n" + P"\n"
  line = C((P(1) - newline)^0) * newline
  Ct line^0 * C(P(1)^0)

class AuditModule extends require "widgets.page"
  header_content: =>
    widget Header {
      show_return: true
    }

  inner_content: =>
    h2 "Rockspec Changes"
    p "This page lists diffs across rockspecs sorted in chronological order."

    unless next @versions
      p "This module has no rockspecs stored that we can diff."

    for version in *@versions
      div class: "version", ->
        div class: "version_header", ->
          h3 ->
            a href: @url_for(version), version\name_for_display!

          @render_date version.created_at

        pre ->
          @render_diff version.rockspec_diff, version

        rocks = version\get_rocks!
        div class: "rocks", ->
          if next rocks
            strong "Rocks:"
            ul ->
              for rock in *rocks
                li ->
                  a href: @url_for(rock), rock.rock_fname
                  text " "
                  code rock.arch
                  text " — "
                  em "Revision #{rock.revision}"
                  text " — "
                  @render_date rock.created_at


          else
            em "No rocks are included with this version"


  flatten_text: (chunk) =>
    -- text chunk
    lines = match_lines\match chunk

    if #lines > 5
      text lines[1] .. "\n"
      text lines[2] .. "\n"
      div class: "truncated", title: "Truncated", "…truncated…\n"
      text lines[#lines-1] .. "\n"
      text lines[#lines]
    else
      text chunk

  render_diff: (changes, version) =>
    unless changes
      em "Missing diff: "
      url = version\url!
      a href: url, "url"
      return

    for {t, chunk} in *changes
      switch t
        when diff.DIFF_EQUAL -- unchanged
          @flatten_text chunk
        when diff.DIFF_INSERT -- add
          span class: "added", chunk
        when diff.DIFF_DELETE -- remove
          span class: "removed", chunk



