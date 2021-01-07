
import use_test_server from require "lapis.spec"

import request, request_as, do_upload_as, should_load from require "spec.helpers"
import from_json from require "lapis.util"

factory = require "spec.factory"

describe "moonrocks", ->
  use_test_server!

  local root

  import
    Manifests
    ManifestModules
    Users
    Modules
    Versions
    Rocks
    Dependencies
    from require "spec.models"

  before_each ->
    root = Manifests\create "root", true

  should_load "/"

  should_load "/about"
  should_load "/m/root"
  should_load "/m/root/development-only"
  should_load "/modules"
  should_load "/manifest"
  should_load "/manifests"

  should_load "/login"
  should_load "/register"
  should_load "/user/forgot_password"

  should_load "/stats"
  should_load "/stats/this-week"
  should_load "/stats/dependencies"

  -- logged out users shouldn't have access
  should_load "/upload", 302
  should_load "/settings", 302
  should_load "/api_keys/new", 302

  it "should detect development version name", ->
    assert.truthy Versions\version_name_is_development "scm-1"
    assert.truthy Versions\version_name_is_development "cvs-2"
    assert.falsy Versions\version_name_is_development "0.2-1"

  describe "search", ->
    should_load "/search"

    it "queries with no modules", ->
      status = request_as nil, "/search", {
        get: { q: "hello world" }
      }

      assert.same 200, status

    it "queries all manifests with no results", ->
      status = request_as nil, "/search", {
        get: {
          q: "hello world"
          non_root: "yes"
        }
      }

      assert.same 200, status

    describe "with results", ->
      before_each ->
        mod = factory.Modules name: "leafo"
        ManifestModules\create root, mod
        factory.Users username: "leafo"

      it "searches root", ->
        status = request_as nil, "/search", {
          get: { q: "leafo" }
        }

        assert.same 200, status

  describe "with user", ->
    local user

    do_upload = (...) ->
      do_upload_as user, ...

    before_each ->
      user = factory.Users!


    it "should load settings page", ->
      status, body = request_as user, "/settings"
      assert.same 302, status

      status, body = request_as user, "/settings/link-github"
      assert.same 200, status

      status, body = request_as user, "/settings/reset-password"
      assert.same 200, status

      status, body = request_as user, "/settings/api-keys"
      assert.same 200, status

      status, body = request_as user, "/settings/profile"
      assert.same 200, status

    describe "reset password", ->
      import UserActivityLogs from require "spec.models"

      it "updates old password", ->
        user\update_password "hello"
        before_hash = user.encrypted_password
        assert not user\check_password "world"

        status, body = request_as user, "/settings/reset-password", {
          post: {
            "password[current_password]": "hello"
            "password[new_password]": "world"
            "password[new_password_repeat]": "world"
          }
        }

        assert.same 302, status

        user\refresh!
        assert user\check_password "world"

        logs = UserActivityLogs\select!
        assert.same 1, #logs
        assert.same "account.update_password", logs[1].action
        assert.same {
          encrypted_password: {
            before: before_hash
            after: user.encrypted_password
          }
        }, logs[1].data


      it "doesn't update when old password is wrong", ->
        user\update_password "hello2"

        status, body = request_as user, "/settings/reset-password", {
          post: {
            "password[current_password]": "hello"
            "password[new_password]": "world"
            "password[new_password_repeat]": "world"
          }
          expect: "json"
        }

        assert.same {
          errors: {"Incorrect old password"}
        }, body

        user\refresh!
        assert user\check_password "hello2"

        logs = UserActivityLogs\select!
        assert.same 1, #logs
        assert.same "account.update_password_attempt", logs[1].action
        assert.same {
          reason: "incorrect old password"
        }, logs[1].data


      it "doesn't update when passwords don't match", ->
        user\update_password "hello"
        assert not user\check_password "world"

        status, body = request_as user, "/settings/reset-password", {
          post: {
            "password[current_password]": "hello"
            "password[new_password]": "world1"
            "password[new_password_repeat]": "world2"
          }
          expect: "json"
        }

        assert.same {
          errors: {"Password repeat does not match"}
        }, body

        user\refresh!
        assert not user\check_password "world1"

        logs = UserActivityLogs\select!
        assert.same 0, #logs

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

      user\refresh!
      assert.same 1, user.modules_count

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

      user\refresh!
      assert.same 1, user.modules_count

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

    it "should not let malicious code in rockspec run", ->
      status, res = do_upload "/upload?json=true", "rockspec_file", "etlua-dev-1.rockspec", [[
        while true do end
      ]]

      assert.same 200, status
      assert.same {errors: {"Failed to eval rockspec"}}, from_json res

    describe "with module", ->
      local mod, version, version_url

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id

        version_url = "/modules/#{user.slug}/#{mod.name}/#{version.version_name}"

      it "should load rock upload page", ->
        status, body, headers = request_as user, "#{version_url}/upload"
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

