
import login_and_return_url from require "helpers.app"


class ModuleHeader extends require "widgets.base"
  @needs: {
    "module"
  }

  admin_panel: =>

  inner_content: =>
    div class: "module_header_inner", ->

      @follow_area!

      h1 ->
        text @module\name_for_display!
        if @version
          text " "
          span class: "sub", @version.version_name

      if summary = @module.summary
        p class: "module_summary", summary

      if @version
        div class: "nav_buttons", ->
          a class: "round_button", href: @url_for(@module), "← Return to module"

      @admin_panel!

    div class: "metadata_columns", ->
      div class: "module_header_inner", ->
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
          div class: "column", ->
            h3 "Homepage"
            a class: "external_url", href: url, @truncate url, 30

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


