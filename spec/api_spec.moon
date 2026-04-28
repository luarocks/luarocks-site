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
        status: 403
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

    describe "two-factor enforced uploads", ->
      totp = require "helpers.totp"
      import TotpSecrets from require "spec.models"
      import escape from require "lapis.util"
      import encode_with_secret from require "lapis.util.encoding"

      etlua_rockspec = -> require("spec.rockspecs.etlua")

      enable_tfa_with_uploads = (require_for_uploads=true) ->
        secret = totp.generate_secret!
        user\enable_totp secret
        if require_for_uploads
          (TotpSecrets\find user.id)\update require_for_uploads: true
        secret

      it "verify_tfa returns a token for a valid code", ->
        secret = enable_tfa_with_uploads!
        res = api_request "/verify_tfa", {
          post: { code: totp.generate_code secret }
        }
        assert.truthy res.success
        assert.is_string res.tfa_token
        assert.is_number res.expires
        assert.truthy res.expires > os.time!

      it "verify_tfa rejects an invalid code", ->
        enable_tfa_with_uploads!
        res = api_request "/verify_tfa", {
          post: { code: "000000" }
          status: 401
        }
        assert.same { errors: {"Invalid verification code"} }, res

      it "verify_tfa rejects when 2FA is not enabled on the account", ->
        res = api_request "/verify_tfa", {
          post: { code: "123456" }
          status: 400
        }
        assert.same {
          errors: {"Two-factor authentication is not enabled on this account"}
        }, res

      it "blocks rockspec upload without a token", ->
        enable_tfa_with_uploads!
        status, res = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
          }
        assert.same 403, status
        assert.same "Two-factor authentication required", res.errors[1]
        assert.truthy res.two_factor_required
        assert.same 0, #Modules\select!

      it "does not gate check_rockspec (read-only)", ->
        enable_tfa_with_uploads!
        res = api_request "/check_rockspec", {
          get: { package: "etlua", version: "1.2.0-1" }
        }
        assert.same {}, res

      it "blocks rock upload without a token", ->
        enable_tfa_with_uploads!
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id
        fname = "#{mod.name}-#{version.version_name}.windows2000.rock"
        status, res = do_upload_as nil, "#{prefix}/upload_rock/#{version.id}",
          "rock_file", fname, "hello world", {
            expect: "json"
          }
        assert.same 403, status
        assert.truthy res.two_factor_required
        assert.same 0, Rocks\count!

      it "allows upload with a valid token", ->
        secret = enable_tfa_with_uploads!
        verify_res = api_request "/verify_tfa", {
          post: { code: totp.generate_code secret }
        }
        url = "#{prefix}/upload?tfa_token=#{escape verify_res.tfa_token}"
        status, res = do_upload_as nil, url, "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
          }
        assert.same 200, status
        assert.truthy res.is_new

      it "rejects an expired token", ->
        enable_tfa_with_uploads!
        token = encode_with_secret {
          api_key: key.key
          user_id: user.id
          expires: os.time! - 60
        }
        url = "#{prefix}/upload?tfa_token=#{escape token}"
        status, res = do_upload_as nil, url, "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
          }
        assert.same 403, status
        assert.truthy res.two_factor_required

      it "rejects a token bound to a different api_key", ->
        enable_tfa_with_uploads!
        token = encode_with_secret {
          api_key: "some-other-key"
          user_id: user.id
          expires: os.time! + 600
        }
        url = "#{prefix}/upload?tfa_token=#{escape token}"
        status, res = do_upload_as nil, url, "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
          }
        assert.same 403, status
        assert.truthy res.two_factor_required

      it "uploads succeed without a token when the setting is off", ->
        enable_tfa_with_uploads false
        status, res = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
          }
        assert.same 200, status
        assert.truthy res.is_new

      it "accepts the token via the X-TFA-Token header", ->
        secret = enable_tfa_with_uploads!
        verify_res = api_request "/verify_tfa", {
          post: { code: totp.generate_code secret }
        }

        status, res = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
          "etlua-1.2.0-1.rockspec", etlua_rockspec!, {
            expect: "json"
            headers: { "X-TFA-Token": verify_res.tfa_token }
          }
        assert.same 200, status
        assert.truthy res.is_new

      it "verify_tfa rejects an oversized code", ->
        enable_tfa_with_uploads!
        api_request "/verify_tfa", {
          post: { code: string.rep "1", 200 }
          status: 400
        }

  describe "with bearer header", ->
    local key, prefix

    bearer_request = (path, opts={}) ->
      opts.expect = "json" unless opts.expect != nil
      opts.headers or= {}
      opts.headers.Authorization or= "Bearer #{key.key}"
      status, res = request "#{prefix}#{path}", opts
      assert.same opts.status or 200, status
      res

    before_each ->
      key = factory.ApiKeys user_id: user.id
      prefix = "/api/1/bearer"

    it "gets key status via Authorization header", ->
      res = bearer_request "/status"
      assert.same user.id, res.user_id

      key\refresh!
      types.assert(types.shape {
        last_used_at: types.string
      }, open: true) ApiKeys\select![1]

    it "rejects missing Authorization header", ->
      status, res = request "#{prefix}/status", { expect: "json" }
      assert.same 401, status
      assert.same {
        errors: {"Missing or malformed Authorization header"}
      }, res

    it "rejects malformed Authorization header", ->
      status, res = request "#{prefix}/status", {
        expect: "json"
        headers: { Authorization: "Token #{key.key}" }
      }
      assert.same 401, status
      assert.same {
        errors: {"Missing or malformed Authorization header"}
      }, res

    it "accepts case-insensitive bearer scheme", ->
      status, res = request "#{prefix}/status", {
        expect: "json"
        headers: { Authorization: "BEARER #{key.key}" }
      }
      assert.same 200, status
      assert.same user.id, res.user_id

    it "rejects revoked key sent via header", ->
      key\revoke!
      res = bearer_request "/status", { status: 403 }
      assert.same {
        errors: {"The API key you provided has been revoked"}
      }, res

    it "rejects unknown key sent via header", ->
      status, res = request "#{prefix}/status", {
        expect: "json"
        headers: { Authorization: "Bearer not-a-real-key" }
      }
      assert.same 401, status
      assert.same { errors: {"Invalid key"} }, res

    it "uploads rockspec via header auth", ->
      status, res = do_upload_as nil, "#{prefix}/upload", "rockspec_file",
        "etlua-1.2.0-1.rockspec", require("spec.rockspecs.etlua"), {
          expect: "json"
          headers: { Authorization: "Bearer #{key.key}" }
        }

      assert.same 200, status
      assert.truthy res.is_new
      assert.same 1, #Modules\select!
      assert.same 1, #Versions\select!
