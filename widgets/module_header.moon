
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
          a href: user_url, @user\name_for_display!

        if license = @module\short_license!
          div class: "column", ->
            h3 "License"
            text license

        if url = @module\format_homepage_url!
          url_title = url\gsub "https?://", ""
          div class: "column", ->
            h3 "Homepage"
            a class: "external_url", rel: "nofollow", href: url, @truncate url_title, 30

        if @version
          div class: "column", ->
            h3 "Version downloads"
            text @format_number @version.downloads
        else
          div class: "column", ->
            h3 "Downloads"
            text @format_number @module.downloads

  follow_area: =>
    div class: "follow_area", ->
      starring_url = if @module_starring
        "unfollow_module"
      else
        "follow_module"

      form {
        action: @url_for(starring_url, module_id: @module.id, kind: "star")
        method: "post"
      }, ->
        @csrf_input!
        if @current_user
          if @module_starring
            button "Unstar"
          else
            button "Star"
        else
          a {
            class:"button"
            href: login_and_return_url(@, nil, "follow_module")
            "Star"
          }

        if @module.starrers_count > 0
          span class: "followers_count", @format_number @module.starrers_count

    span
      
    div class: "follow_area", ->
      follow_url = if @module_following
        "unfollow_module"
      else
        "follow_module"

      form {
        action: @url_for(follow_url, module_id: @module.id, kind: "follow")
        method: "post"
      }, ->
        @csrf_input!
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
