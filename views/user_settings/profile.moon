
class UserSettingsProfile extends require "widgets.user_settings_page"
  settings_content: =>
    form class: "form", method: "post", ->
      @csrf_input!
      data = @user\get_data!

      div class: "row", ->
        label ->
          div class: "label", "Email address"

        div class: "medium_input", @user.email

      div class: "row", ->
        label ->
          div class: "label", "Your website"

        input {
          type: "text"
          class: "medium_input"
          name: "profile[website]"
          placeholder: "https://..."
          value: data.website and @format_url data.website
        }

      div class: "row", ->
        label ->
          div class: "label", "Twitter account"

        input {
          type: "text"
          class: "medium_input"
          name: "profile[twitter]"
          placeholder: "@helloworld"
          value: data.twitter and "@#{data\twitter_handle!}"
        }

      div class: "row", ->
        label ->
          div class: "label", "GitHub account"

        github_accounts = @user\get_github_accounts!
        if github_accounts and #github_accounts > 0
          div class: "medium_input", ->
            for account in *github_accounts
              div ->
                a href: account\profile_url!, target: "_blank", account.github_login
                text " "
                span class: "sub", ->
                  text "(connected "
                  @render_date account.created_at
                  text " | "
                  a href: @url_for("github_remove", account), "Remove..."
                  text ")"
        else
          input {
            type: "text"
            class: "medium_input"
            name: "profile[github]"
            value: data.github and data\github_handle!
          }

      div class: "row", ->
        label ->
          div class: "label", "Profile"

        textarea name: "profile[profile]", data.profile

      div class: "button_row", ->
        button class: "button", "Submit"

