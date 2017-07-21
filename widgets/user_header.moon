import time_ago_in_words from require "lapis.util"
import login_and_return_url from require "helpers.app"
  
class UserHeader extends require "widgets.page_header"
  @needs: {
    "user"
  }

  admin_panel: =>

  inner_content: =>
    div class: "page_header_inner", ->
      if not @current_user or @current_user.id != @user.id
        @render_follow_area!

      div class: "social_links", ->
        data = @user\get_data!
        if github = data\github_handle!
          a href: "https://github.com/#{github}", title: github, ->
            span class: "icon-github"

        if twitter = data\twitter_handle!
          a href: "https://twitter.com/#{twitter}", title: twitter, ->
            span class: "icon-twitter"

      h1 ->
        a href: @url_for(@user), ->
          img class: "avatar", src: @user\gravatar(60)

        span class: "username", @user\name_for_display!

        if @user\is_admin!
          div class: "user_flag", "Admin"

    div class: "metadata_columns", ->
      module_count = @pager\total_items!

      div class: "page_header_inner", ->
        div class: "column", ->
          h3 "Modules"
          text @format_number module_count

        div class: "column", ->
          h3 "Registered"
          span title: @user.created_at, time_ago_in_words @user.created_at

        if module_count > 0
          div class: "column", ->
            h3 "Downloads"
            text @format_number @user\count_downloads!

        if url = @user\get_data!.website
          div class: "column", ->
            h3 "Website"
            url_title = url\gsub "https?://", ""
            a {
              class: "external_url"
              rel: "nofollow"
              href: @format_url url
              @truncate url_title, 30
            }


  render_follow_area: =>
    div class: "follow_area", ->
      form {
        action: @url_for(@user_following and "unfollow_user" or"follow_user", slug: @user.slug)
        method: "post"
            }, ->
        @csrf_input!
        if @current_user
          if @user_following
            button "Unfollow"
          else
            button "Follow"
        else
          a {
            class:"button"
            href: login_and_return_url(@, nil, "follow_user")
            "Follow"
          }

        if @user.followers_count > 0
          span class: "followers_count", @format_number @user.followers_count
