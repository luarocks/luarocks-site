
lapis = require "lapis"

import
  assert_csrf
  require_login
  from require "helpers.app"

import
  capture_errors
  capture_errors_json
  assert_error
  respond_to
  from require "lapis.application"

import assert_valid from require "lapis.validate"

import GithubAccounts from require "models"
import Users from require "models"

class MoonrocksGithub extends lapis.Application
  [github_auth: "/github/auth"]: capture_errors {
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

      if @current_user
        -- There is an User that has been logged in.
        -- If the GitHub account isn't linked to another user, links to the @current_user
        -- Otherwise, links the GitHub account to @current_user

        if account = GithubAccounts\find user_id: @current_user.id, github_user_id: user.id
          account\update data
        else
          GithubAccounts\create data

        data = @current_user\get_data!

        unless data.github
          data\update github: user.login

        redirect_to: @url_for "user_settings.link_github"
      else
        -- There isn't an User logged in
        -- See whether the GitHub account is linked to an existing account
        -- If so, log in with the existing account
        -- Otherwise, create a new account with data fetched from GitHub

        if account = GithubAccounts\find github_user_id: user.id
          -- Log in user
          assert_error Users\login @params.username, @params.password
        else
          -- User objects need an username and a password
          -- In case of a conflict with the GitHub account username, should we use a random username creator ?
          -- For a password, what should be the best idea ?
          username = ""
          password = ""

          luarocks_user = User\create username, password, user.email

          data.user_id = luarocks_user.id

          assert_error GithubAccounts\create data

          redirect_to: @url_for luarocks_user
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

      redirect_to: @url_for "user_settings.link_github"
  }


  [github_claim_modules: "/github/claim"]: require_login respond_to {
    before: =>
      import Users, LinkedModules from require "models"

      accounts = @current_user\find_github_accounts!

      modules = {}
      for account in *accounts
        for m in *account\modules_for_account!
          table.insert modules, m

      Users\include_in modules, "user_id"

      linked = if next modules
        module_ids = table.concat [m.id for m in *modules], ", "
        LinkedModules\select [[
          where user_id = ? and module_id in (]] .. module_ids .. [[)
        ]], @current_user.id
      else
        {}


      linked_by_id = {link.module_id, true for link in *linked}

      @linked_modules = {}
      @claimable_modules = {}

      for m in *modules
        if linked_by_id[m.id]
          table.insert @linked_modules, m
        else
          table.insert @claimable_modules, m

    GET: =>
      render: true

    POST: =>
      ngx.sleep 3

      for mod in *@claimable_modules
        mod\copy_to_user @current_user, true

      redirect_to: @url_for("github_claim_modules")

  }
