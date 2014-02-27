-- User management actions not related to modules

lapis = require "lapis"
db = require "lapis.db"

import
  respond_to
  capture_errors
  assert_error
  from require "lapis.application"

import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import
  ApiKeys
  Users
  from require "models"

import
  assert_csrf
  require_login
  from require "helpers.apps"


assert_table = (val) ->
  assert_error type(val) == "table", "malformed input, expecting table"
  val

validate_reset_token = =>
  if @params.token
    assert_valid @params, {
      { "id", is_integer: true }
    }

    @user = assert_error Users\find(@params.id), "invalid token"
    @user\get_data!
    assert_error @user.data.password_reset_token == @params.token, "invalid token"
    @token = @params.token
    true

class MoonRocksUser extends lapis.Application
  [user_login: "/login"]: respond_to {
    before: =>
      @title = "Login"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_valid @params, {
        { "username", exists: true }
        { "password", exists: true }
      }

      user = assert_error Users\login @params.username, @params.password
      user\write_session @
      redirect_to: @url_for"index"
  }

  [user_register: "/register"]: respond_to {
    before: =>
      @title = "Register Account"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_valid @params, {
        { "username", exists: true, min_length: 2, max_length: 25 }
        { "password", exists: true, min_length: 2 }
        { "password_repeat", equals: @params.password }
        { "email", exists: true, min_length: 3 }
      }

      {:username, :password, :email } = @params
      user = assert_error Users\create username, password, email

      user\write_session @
      redirect_to: @url_for"index"
  }

  -- TODO: make this post
  [user_logout: "/logout"]: =>
    @session.user = false
    redirect_to: "/"

  [user_forgot_password: "/user/forgot_password"]: respond_to {
    GET: capture_errors =>
      validate_reset_token @
      render: true

    POST: capture_errors =>
      assert_csrf @

      if validate_reset_token @
        assert_valid @params, {
          { "password", exists: true, min_length: 2 }
          { "password_repeat", equals: @params.password }
        }
        @user\update_password @params.password, @
        @user.data\update { password_reset_token: db.NULL }
        redirect_to: @url_for"index"
      else
        assert_valid @params, {
          { "email", exists: true, min_length: 3 }
        }

        user = assert_error Users\find(email: @params.email),
          "don't know anyone with that email"

        token = user\generate_password_reset!

        reset_url = @build_url @url_for"user_forgot_password",
          query: "token=#{token}&id=#{user.id}"

        user\send_email "Reset your password", ->
          h2 "Reset Your Password"
          p "Someone attempted to reset your password. If that person was you, click the link below to update your password. If it wasn't you then you don't have to do anything."
          p ->
            a href: reset_url, reset_url

        redirect_to: @url_for"user_forgot_password" .. "?sent=true"
  }

  [user_settings: "/settings"]: require_login respond_to {
    before: =>
      @user = @current_user
      @user\get_data!
      @title = "User Settings"

    GET: =>
      @api_keys = ApiKeys\select "where user_id = ?", @user.id
      render: true

    POST: capture_errors =>
      assert_csrf @

      if passwords = @params.password
        assert_table passwords
        trim_filter passwords

        assert_valid passwords, {
          { "new_password", exists: true, min_length: 2 }
          { "new_password_repeat", equals: passwords.new_password }
        }

        assert_error @user\check_password(passwords.current_password),
          "Invalid old password"

        @user\update_password passwords.new_password, @

      redirect_to: @url_for"user_settings" .. "?password_reset=true"
  }
