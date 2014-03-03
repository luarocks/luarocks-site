-- app responsible for rendering manifests

MANIFEST_LUA_VERSIONS = { "5.1", "5.2" }

lapis = require "lapis"

import
  assert_error
  capture_errors
  from require "lapis.application"

import assert_valid from require "lapis.validate"

import
  Manifests
  Modules
  Users
  from require "models"

import render_manifest from require "helpers.manifests"

class MoonRocksApi extends lapis.Application
  [root_manifest: "/manifest"]: =>
    modules = Manifests\root!\all_modules fields: "id, name"
    render_manifest @, modules

  "/manifest-:version": capture_errors {
    on_error: =>
      "Not found", status: 404

    =>
      assert_valid @params, {
        { "version", one_of: MANIFEST_LUA_VERSIONS }
      }

      modules = Manifests\root!\all_modules fields: "id, name"
      render_manifest @, modules, @params.version
  }

  "/manifests/:user/manifest-:version": capture_errors {
    on_error: =>
      "Not found", status: 404

    =>
      assert_valid @params, {
        { "version", one_of: MANIFEST_LUA_VERSIONS }
      }

      user = assert_error Users\find(slug: @params.user), "Invalid user"
      render_manifest @, user\all_modules(fields: "id, name"), @params.version
  }


  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)

  [user_manifest: "/manifests/:user/manifest"]: =>
    user = assert Users\find(slug: @params.user), "Invalid user"
    render_manifest @, user\all_modules fields: "id, name"


