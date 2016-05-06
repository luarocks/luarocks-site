
import login_and_return_url from require "helpers.app"

class ModuleHeader extends require "widgets.page_header"
  @needs: {
    "module"
  }

  admin_panel: =>

  inner_content: =>
    div class: "page_header_inner", ->
      @follow_area!

      h1 ->
        text @module\name_for_display!
        if @version
          text " "
          span class: "sub", @version.version_name

          if @version.archived
            span {
              title: "Not available in manifest"
              class: "archive_flag"
            }, "Archived"

      if summary = @module.summary
        p class: "module_summary", summary

      if @version
        div class: "nav_buttons", ->
          a class: "round_button", href: @url_for(@module), "← Return to module"

      @admin_panel!

    div class: "metadata_columns", ->
      div class: "page_header_inner", ->
        div class: "column", ->
          h3 "Uploader"
          user_url = @url_for "user_profile", user: @user.slug
          a href: user_url, -> img class: "avatar", src: @user\gravatar(20)
          a href: user_url, @user.username

        if license = @module\short_license!
          div class: "column", ->
            h3 "License"
            text license

        if url = @module\format_homepage_url!
          url_title = url\gsub "https?://", ""
          div class: "column", ->
            h3 "Homepage"
            a class: "external_url", rel: "nofollow", href: url, @truncate url_title, 30

        if url = @module\format_homepage_url!
          url_title = url\gsub "https?://", ""
          div class: "column", ->
            h3 "Github"
            a class: "external_url", rel: "nofollow", href: url, @truncate url_title, 30

        if @version
          div class: "column", ->
            h3 "Version downloads"
            text @format_number @version.downloads
        else
          div class: "column", ->
            h3 "Downloads"
            text @format_number @module.downloads

  endorse_area: =>
    div class: "endorse_area", ->
      form {
        action: @url_for(@module_endorsing and "unendorse_module" or"endorse_module", module_id: @module.id)
        method: "post"
      }, ->
        @csrf_input
        if @current_user
          if @module_endorsing
            button "Stop Endorsing"
          else
            button "Endorse"
        else
          a {
            class:"button"
            href: login_and_return_url(@, nil, "endorse_module")
            "Endorse"
          }

        --if @module.followers_count > 0
          --span class: "followers_count", @format_number @module.followers_count


  follow_area: =>
    div class: "follow_area", ->
      form {
        action: @url_for(@module_following and "unfollow_module" or"follow_module", module_id: @module.id)
        method: "post"
      }, ->
        @csrf_input
        if @current_user
          if @module_following
            button "Unfollow"
          else
            button "Follow"
        else
          a {
            class:"button"
            href: login_and_return_url(@, nil, "follow_module")
            "Follow"
          }

        if @module.followers_count > 0
          span class: "followers_count", @format_number @module.followers_count


