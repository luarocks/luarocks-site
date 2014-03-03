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
  Versions
  Rocks
  from require "models"

import render_manifest, preload_modules from require "helpers.manifests"
import get_all_pages from require "helpers.models"

capture_errors_404 = (fn) ->
  capture_errors {
    on_error: => "Not found", status: 404
    fn
  }

handle_render = (obj, filter_version) =>
  pager = obj\find_modules {
    fields: "id, name"
    per_page: 50
    prepare_results: preload_modules
  }

  modules = get_all_pages pager
  render_manifest @, modules, filter_version

assert_filter = =>
  assert_valid @params, {
    { "version", one_of: MANIFEST_LUA_VERSIONS }
  }

  @params.version


class MoonRocksApi extends lapis.Application
  [root_manifest: "/manifest"]: =>
    handle_render @, Manifests\root!

  "/manifest-:version": capture_errors_404 =>
    filter_version = assert_filter @
    handle_render @, Manifests\root!, filter_version

  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)

  [user_manifest: "/manifests/:user/manifest"]: capture_errors_404 =>
    user = assert_error Users\find(slug: @params.user), "Invalid user"
    handle_render @, user

  "/manifests/:user/manifest-:version": capture_errors_404 =>
    user = assert_error Users\find(slug: @params.user), "Invalid user"
    filter_version = assert_filter @
    handle_render @, user, filter_version

