
class UserSettingsProfile extends require "widgets.user_settings_page"
  settings_content: =>
    form class: "form", method: "post", ->
      @csrf_input!
      data = @user\get_data!

      div class: "row", ->
        label ->
          div class: "label", "Your email"

        input {
          type: "text"
          class: "medium_input"
          name: "email"
          value: @user.email
        }

      div class: "row", ->
        label ->
          div class: "label", "Your website"

        input {
          type: "text"
          class: "medium_input"
          name: "profile[website]"
          placeholder: "http://..."
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

