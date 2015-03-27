
import load_test_server, close_test_server, request
  from require "lapis.spec.server"

should_load = (url, expected_status=200) ->
  it "should load #{url} with #{expected_status}", ->
    assert.same expected_status, (request url)

import truncate_tables from require "lapis.spec.db"

import request_as, do_upload_as from require "spec.helpers"

import generate_token from require "lapis.csrf"

import from_json from require "lapis.util"

import
  Manifests
  ManifestModules
  Users
  Modules
  Versions
  Rocks
  Dependencies
  from require "models"

factory = require "spec.factory"

describe "moonrocks", ->
  local root

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Manifests, Users, Modules, Versions, Rocks, ManifestModules, Dependencies
    root = Manifests\create "root", true

  should_load "/"

  should_load "/about"
  should_load "/m/root"
  should_load "/m/root/development-only"
  should_load "/modules"
  should_load "/manifest"

  should_load "/login"
  should_load "/register"
  should_load "/user/forgot_password"

  -- logged out users shouldn't have access
  should_load "/upload", 302
  should_load "/settings", 302
  should_load "/api_keys/new", 302

  it "should detect development version name", ->
    assert.truthy Versions\version_name_is_development "scm-1"
    assert.truthy Versions\version_name_is_development "cvs-2"
    assert.falsy Versions\version_name_is_development "0.2-1"

  describe "with user", ->
    local user

    do_upload = (...) ->
      do_upload_as user, ...

    before_each ->
      user = factory.Users!

    it "should load settings page", ->
      status, body = request_as user, "/settings"
      assert.same 200, status

    it "should load upload page", ->
      status, body = request_as user,  "/upload"
      assert.same 200, status

    it "should upload rockspec", ->
      status, body, headers = do_upload "/upload", "rockspec_file",
        "etlua-1.2.0-1.rockspec", require("spec.rockspecs.etlua")

      assert.same 302, status
      assert.truthy headers.location\match "/modules/"
      versions = Versions\select!
      assert.same 1, #versions
      version = unpack versions
      assert.same false, version.development
      assert.same "etlua-1.2.0-1.rockspec", version.rockspec_fname
      assert.same "1.2.0-1", version.version_name
      assert.same "git://github.com/leafo/etlua.git", version.source_url
      assert.same "lua >= 5.1", version.lua_version

      mod = version\get_module!
      assert.same false, mod.has_dev_version

      root_after = Manifests\find(root.id)
      assert.same 1, root_after.modules_count
      assert.same 1, root_after.versions_count

      deps = Dependencies\select "order by dependency asc"
      assert.same {
        {
          version_id: version.id
          dependency_name: "lapis"
          dependency: "lapis"
        },
        {
          version_id: version.id
          dependency_name: "lua"
          dependency: "lua >= 5.1"
        }
      }, deps


    it "should override rockspec", ->
      mod = factory.Modules user_id: user.id, name: "etlua"
      version = factory.Versions {
        module_id: mod.id
        version_name: "1.2.0-1"
        rockspec_fname: "etlua-1.2.0-1.rockspec"
      }

      status, body, headers = do_upload "/upload?json=true", "rockspec_file",
        "etlua-1.2.0-1.rockspec", require("spec.rockspecs.etlua")

      assert.same 1, #Modules\select!
      assert.same 1, #Versions\select!

      version\refresh!
      assert.same 2, version.revision

    it "should upload development rockspec", ->
      status, body, headers = do_upload "/upload", "rockspec_file",
        "enet-dev-1.rockspec", require("spec.rockspecs.enet_dev")

      assert.same 302, status
      assert.truthy headers.location\match "/modules/"
      versions = Versions\select!
      assert.same 1, #versions
      version = unpack versions
      assert.same true, version.development
      assert.same "enet-dev-1.rockspec", version.rockspec_fname
      assert.same "dev-1", version.version_name
      assert.same "git://github.com/leafo/lua-enet.git", version.source_url
      assert.same "lua >= 5.1", version.lua_version

      mod = version\get_module!
      assert.same true, mod.has_dev_version

      root_after = Manifests\find(root.id)
      assert.same 1, root_after.modules_count
      assert.same 1, root_after.versions_count

    it "should not upload invalid rockspec", ->
      status = do_upload "/upload", "rockspec_file", "etlua-dev-1.rockspec", "hello world"
      assert.same 200, status
      assert.same 0, #Versions\select!

    it "should not let code in rockspec run", ->
      status, res = do_upload "/upload?json=true", "rockspec_file", "etlua-dev-1.rockspec", [[
        print 'what the check'
      ]]

      assert.same {errors: {"Failed to eval rockspec"}}, from_json res
      assert.same 200, status
      assert.same 0, #Versions\select!

    it "should not let malicious code in rockspec run #ddd", ->
      status, res = do_upload "/upload?json=true", "rockspec_file", "etlua-dev-1.rockspec", [[
        while true do end
      ]]

      -- no way to pcall capture debug hook in luajit so we just let it blow
      -- up, better than crashing server
      assert.same 500, status

    describe "with module", ->
      local mod, version, version_url

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id

        version_url = "/modules/#{user.slug}/#{mod.name}/#{version.version_name}"

      it "should load rock upload page", ->
        status, body = request_as user, "#{version_url}/upload"
        assert.same 200, status

      it "should not load rock upload page for not owner", ->
        status, body = request "#{version_url}/upload"
        assert.same 302, status

        other_user = factory.Users!

        status, body = request_as other_user, "#{version_url}/upload"
        assert.same 404, status

      it "should upload rock", ->
        fname = "#{mod.name}-#{version.version_name}.windows2000.rock"
        status, body = do_upload "#{version_url}/upload", "rock_file", fname, "hello world"
        assert.same 302, status
        rock = assert unpack Rocks\select!
        assert.same "windows2000", rock.arch

      it "should upload new version of rock", ->
        rock = factory.Rocks version_id: version.id, arch: "windows2000"

        fname = "#{mod.name}-#{version.version_name}.windows2000.rock"
        do_upload "#{version_url}/upload", "rock_file", fname, "hello world"
        assert.same 1, #Rocks\select!

        rock\refresh!
        assert.same 2, rock.revision

