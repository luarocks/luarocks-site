
import login_and_return_url from require "helpers.app"

class ModuleHeader extends require "widgets.page_header"
  @needs: {
    "module"
  }

  admin_panel: =>

  inner_content: =>
    div class: "page_header_inner", ->
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


      div class: "right_tools", ->
        @follow_area!

    div class: "page_header_inner", ->
      if summary = @module.summary
        p class: "module_summary", summary

    if @version
      div class: "page_header_inner", ->
        div class: "nav_buttons", ->
          a class: "round_button", href: @url_for(@module), "← Return to module"

    @admin_panel!

    div class: "metadata_columns", ->
      div class: "metadata_columns_inner", ->
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


  render_star_form: =>
    starring_url = if @module_starring
      "unfollow_module"
    else
      "follow_module"

    form {
      action: @url_for(starring_url, module_id: @module.id, type: "bookmark")
      method: "post"
    }, ->
      @csrf_input!

      inside = if @module_starring
        -> text "Unstar"
      else
        ->
          @icon "star", 18
          text " Star"

      if @current_user
        button inside
      else
        a {
          class:"button"
          href: login_and_return_url(@, nil, "follow_module")
        }, inside

      if @module.stars_count > 0
        span class: "followers_count", @format_number @module.stars_count

  render_follow_form: =>
    follow_url = if @module_following
      "unfollow_module"
    else
      "follow_module"

    form {
      action: @url_for(follow_url, module_id: @module.id, type: "subscription")
      method: "post"
    }, ->
      @csrf_input!


      inside = if @module_following
        -> text "Unfollow"
      else
        ->
          @icon "user_plus", 18
          text " Follow"

      if @current_user
        if @module_following
          button inside
        else
          button inside
      else
        a {
          class:"button"
          href: login_and_return_url(@, nil, "follow_module")
        }, inside

      if @module.followers_count > 0
        span class: "followers_count", @format_number @module.followers_count

  follow_area: =>
    div class: "follow_area", ->
      @render_follow_form!
      @render_star_form!

