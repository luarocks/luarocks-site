import request, request_as, do_upload_as from require "spec.helpers"

factory = require "spec.factory"

import use_test_server from require "lapis.spec"

import types from require "tableshape"

describe "application.api", ->
  use_test_server!

  local root, user

  import Users, ApiKeys, Manifests, ManifestModules,
    Modules, Versions, Rocks from require "spec.models"

  before_each ->
    root = Manifests\create "root", true
    user = Users\create "leafo", "leafo", "leafo@example.com"

  it "should create an api key", ->
    status, body = request_as user, "/api_keys/new", {
      post: {}
    }
    assert.same 302, status
    assert.same 1, #ApiKeys\select!

    types.assert(types.shape {
      key: types.string
      user_id: user.id
      revoked: false
      last_used_at: types.nil
    }, open: true) ApiKeys\select![1]

  it "should get tool version", ->
    status, res = request_as nil, "/api/tool_version", {
      expect: "json"
    }

    assert.same 200, status
    config = require"lapis.config".get!
    assert.same {version: config.tool_version}, res

  describe "with key", ->
    local key, prefix

    api_request = (path, opts={}) ->
      opts.expect = "json" unless opts.expect != nil
      status, res = request "#{prefix}#{path}", opts
      assert.same opts.status or 200, status

      res

    before_each ->
      key = factory.ApiKeys user_id: user.id
      prefix = "/api/1/#{key.key}"

    it "gets key status", ->
      res = api_request "/status"
      assert.same user.id, res.user_id

      assert.nil key.last_used_at

      key\refresh!

      -- last used at updated
      types.assert(types.shape {
        last_used_at: types.string
      }, open: true) ApiKeys\select![1]

    it "blocks revoked key", ->
      key\revoke!
      res = api_request "/status", {
        status: 200
      }

      assert.same {
        errors: {"The API key you provided has been revoked"}
      }, res

    it "blocks suspended user", ->
      user\update flags: Users.flags.suspended
      res = api_request "/status", {
        status: 403
      }

      assert.same {
        errors: {"Your account has been suspended"}
      }, res

    it "suspended user cannot upload rockspec", ->
      user\update flags: Users.flags.suspended
      status, res = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
        "etlua-1.2.0-1.rockspec", require("spec.rockspecs.etlua"), {
          expect: "json"
        }

      assert.same 403, status
      assert.same {
        errors: {"Your account has been suspended"}
      }, res

      assert.same 0, #Versions\select!
      assert.same 0, #Modules\select!

    it "suspended user cannot upload rock", ->
      mod = factory.Modules user_id: user.id
      version = factory.Versions module_id: mod.id

      user\update flags: Users.flags.suspended

      fname = "#{mod.name}-#{version.version_name}.windows2000.rock"
      status, res = do_upload_as nil, "#{prefix}/upload_rock/#{version.id}",
        "rock_file", fname, "hello world", {
          expect: "json"
        }

      assert.same 403, status
      assert.same {
        errors: {"Your account has been suspended"}
      }, res

      assert.same 0, Rocks\count!

    it "checks nonexistent rockspec", ->
      res = api_request "/check_rockspec", {
        get: {
          package: "hello"
          version: "1-1"
        }
      }

      assert.same {}, res

    it "uploads rockspec", ->
      status, res, headers = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
        "etlua-1.2.0-1.rockspec", require("spec.rockspecs.etlua"), {
          expect: "json"
        }

      assert.same 200, status
      assert.truthy res.module_url
      assert.truthy res.version
      assert.truthy res.module
      assert.truthy res.is_new

      versions = Versions\select!
      assert.same 1, #versions
      version = unpack versions
      assert.same version.id, res.version.id

      modules = Modules\select!
      assert.same 1, #modules
      mod = unpack modules
      assert.same mod.id, res.module.id

      -- adds to root manifest
      assert.same 1, #res.manifests
      root\refresh!
      assert.same 1, root.modules_count

      key\refresh!

      -- last used at updated
      types.assert(types.shape {
        last_used_at: types.string
        actions: 1
      }, open: true) ApiKeys\select![1]


    it "fails to upload rock on invalid version", ->
      fname = "hello-1.0.windows2000.rock"
      status, res = do_upload_as nil, "#{prefix}/upload_rock/#{239023}",
        "rock_file", fname, "hello world", {
          expect: "json"
        }

      assert.same 404, status
      assert.same {
        errors: {"invalid version"}
      }, res

    it "fails to upload rock for module not owned by user", ->
      -- someone elses module
      mod = factory.Modules!
      version = factory.Versions module_id: mod.id

      fname = "#{mod.name}-#{version.version_name}.windows2000.rock"

      status, res = do_upload_as nil, "#{prefix}/upload_rock/#{version.id}",
        "rock_file", fname, "hello world", {
          expect: "json"
        }

      assert.same 400, status
      assert.same {
        errors: {"Don't have permission to edit"}
      }, res

      assert.same 0, Rocks\count!

    it "should upload rock", ->
      mod = factory.Modules user_id: user.id
      version = factory.Versions module_id: mod.id

      fname = "#{mod.name}-#{version.version_name}.windows2000.rock"
      status, res = do_upload_as nil, "#{prefix}/upload_rock/#{version.id}",
        "rock_file", fname, "hello world", {
          expect: "json"
        }

      assert.same 200, status
      assert.truthy res.rock
      assert.truthy res.module_url

      rock = assert unpack Rocks\select!
      assert.same "windows2000", rock.arch

