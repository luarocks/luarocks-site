
lapis = require "lapis"

import
  assert_csrf
  require_login
  from require "helpers.apps"

import
  capture_errors
  capture_errors_json
  assert_error
  respond_to
  from require "lapis.application"

import assert_valid from require "lapis.validate"

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

      if account = GithubAccounts\find user_id: @current_user.id, github_user_id: user.id
        account\update data
      else
        GithubAccounts\create data

      redirect_to: @url_for "user_settings"
  }


  [github_remove: "/github/remove/:github_user_id"]: require_login capture_errors_json respond_to {
    before: =>
      assert_valid @params, {
        {"github_user_id", is_integer: true}
      }

      @account = GithubAccounts\find {
        user_id: @current_user.id
        github_user_id: @params.github_user_id
      }

      assert_error @account, "invalid account"

    GET: =>
      render: true

    POST: =>
      @account\delete!

      github = require "helpers.github"
      github\delete_access_token @account.access_token

      redirect_to: @url_for "user_settings"
  }


