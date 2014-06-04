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
import zipped_file from require "helpers.zip"

import cached from require "lapis.cache"

config = require("lapis.config").get!

serve_manifest = capture_errors_404 =>
  if @params.version
    -- check for zip in version
    if @params.version\match "%.zip$"
      @zip = true
      @params.version = @params.version\sub 1, -5

    assert_valid @params, {
      { "version", one_of: MANIFEST_LUA_VERSIONS }
    }

    @version = @params.version

  -- find what we are fetching modules from
  thing = if @params.user
    assert_error Users\find(slug: @params.user), "invalid user"
  else
    Manifests\root!

  if thing.__class == Manifests
    date = require "date"
    @res\add_header "Last-Modified", date(thing.updated_at)\fmt "${http}"

    -- on HEAD just return last modified
    if @req.cmd_mth == "HEAD"
      return { layout: false }

  -- get the modules
  pager = thing\find_modules {
    fields: "id, name"
    per_page: 50
    prepare_results: preload_modules
  }

  modules = get_all_pages pager
  manifest_text = render_manifest @, modules, @version, @development

  -- render to zip file if necessary
  if @zip
    fname = "manifest"
    if @version
      fname ..= "-#{@version}"

    @res.headers["Content-Type"] = "application/zip"
    return layout: false, zipped_file fname, manifest_text

  layout: false, manifest_text

cached_manifest = (fn) ->
  cached {
    dict: "manifest_cache"
    cache_key: (path) -> path
    exptime: 60 * 10
    when: -> config._name == "production"
    fn
  }

is_dev = (fn) ->
  =>
    @development = true
    fn @

is_stable = (fn) ->
  =>
    @development = false
    fn @

class MoonRocksManifest extends lapis.Application
  [root_manifest: "/manifest"]: cached_manifest is_stable serve_manifest

  [root_manifest_dev: "/dev/manifest"]: cached_manifest is_dev serve_manifest

  "/manifest-:version": cached_manifest is_stable serve_manifest

  "/dev/manifest-:version": cached_manifest is_dev serve_manifest

  [user_manifest: "/manifests/:user/manifest"]: serve_manifest

  "/manifests/:user/manifest-:version": serve_manifest

  "/dev": => redirect_to: @url_for "root_manifest_dev"
  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)


