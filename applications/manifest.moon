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
import capture_errors_404 from require "helpers.apps"

import cached from require "lapis.cache"

config = require("lapis.config").get!

handle_render = (obj, ...) =>
  pager = obj\find_modules {
    fields: "id, name"
    per_page: 50
    prepare_results: preload_modules
  }

  modules = get_all_pages pager
  render_manifest @, modules, ...

assert_filter = =>
  assert_valid @params, {
    { "version", one_of: MANIFEST_LUA_VERSIONS }
  }

  @params.version

cached_manifest = (fn) ->
  cached {
    dict: "manifest_cache"
    cache_key: (path) -> path
    exptime: 60 * 10
    when: -> config._name == "production"
    fn
  }


render_root_manifest = =>
  filter_version = if @params.version then assert_filter @
  handle_render @, Manifests\root!, filter_version, @development

class MoonRocksManifest extends lapis.Application
  [root_manifest: "/manifest"]: cached_manifest =>
    render_root_manifest @

  [root_manifest_dev: "/dev/manifest"]: cached_manifest =>
    @development = true
    render_root_manifest @

  "/manifest-:version": capture_errors_404 cached_manifest =>
    render_root_manifest @

  "/dev/manifest-:version": capture_errors_404 cached_manifest =>
    @development = true
    render_root_manifest @

  "/dev": => redirect_to: @url_for "root_manifest_dev"

  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)

  [user_manifest: "/manifests/:user/manifest"]: capture_errors_404 =>
    user = assert_error Users\find(slug: @params.user), "Invalid user"
    handle_render @, user

  "/manifests/:user/manifest-:version": capture_errors_404 =>
    user = assert_error Users\find(slug: @params.user), "Invalid user"
    filter_version = assert_filter @
    handle_render @, user, filter_version




