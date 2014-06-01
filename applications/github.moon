
lapis = require "lapis"

import
  assert_csrf
  require_login
  from require "helpers.apps"

import
  capture_errors
  assert_error
  from require "lapis.application"


import GithubAccounts from require "models"

class MoonrocksGithub extends lapis.Application
  [github_auth: "/github/auth"]: require_login capture_errors {
    on_error: =>
      render: "errors"

    =>
      @params.csrf_token = @params.state
      assert_csrf @

      github = require "helpers.github"
      access = assert_error github\access_token @params.code
      user = assert_error github\user access.access_token

      data = {
        user_id: @current_user.id
        github_user_id: user.id
        github_login: user.login
        access_token: access.access_token
      }

      if gh = GithubAccounts\find user_id: @current_user.id, github_user_id: user.id
        gh\update data
      else
        GithubAccounts\create data

      redirect_to: @url_for "user_settings"
  }


