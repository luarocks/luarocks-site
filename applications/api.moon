
lapis = require "lapis"

import
  respond_to
  capture_errors
  capture_errors_json
  assert_error
  from require "lapis.application"

import assert_valid from require "lapis.validate"

import
  ApiKeys
  FileAudits
  ManifestModules
  Manifests
  Modules
  Users
  Versions
  from require "models"

import
  handle_rock_upload
  handle_rockspec_upload
  from require "helpers.uploaders"

import
  assert_csrf
  require_login
  from require "helpers.app"

INVALID_KEY = {
  status: 401
  json: { errors: {"Invalid key"} }
}

api_request = (fn) ->
  capture_errors {
    on_error: =>
      {
        status: 400
        json: { errors: @errors }
      }

    =>
      @key = ApiKeys\find(key: @params.key)

      unless @key
        return INVALID_KEY

      if @key.revoked
        return {
          -- TODO: luarocks currently doesn't show error codes when non-200
          status: 200
          json: {
            errors: {
              "The API key you provided has been revoked. If you didn't revoke it then it may have been automatically revoked. See here: https://luarocks.org/security-incident-march-2019 You can generate a new API key here: https://luarocks.org/settings/api-keys"
            }
          }
        }

      @key\update_last_used_at!
      @current_user = Users\find id: @key.user_id

      if @current_user\is_suspended!
        return {
          status: 403
          json: { errors: {"Your account has been suspended"} }
        }

      fn @
  }

class MoonRocksApi extends lapis.Application
  [new_api_key: "/api_keys/new"]: require_login respond_to {
    POST: capture_errors {
      on_error: => redirect_to: @url_for "user_settings.api_keys"

      =>
        assert_csrf @
        key = ApiKeys\generate @current_user.id

        import UserActivityLogs from require "models"

        UserActivityLogs\create_from_request @, {
          user_id: @current_user.id
          action: "account.create_api_key"
          source: "web"
          data: {
            key: key.key
          }
        }

        redirect_to: @url_for "user_settings.api_keys"
    }
  }

  [delete_api_key: "/api_key/:key/delete"]: require_login capture_errors {
    on_error: => redirect_to: @url_for "user_settings.api_keys"

    respond_to {
      before: =>
        @key = ApiKeys\find user_id: @current_user.id, key: @params.key
        assert_error @key, "Invalid key"
        assert_error not @key.revoked, "Invalid key"

      GET: => render: true

      POST: =>
        assert_csrf @
        @key\revoke!

        import UserActivityLogs from require "models"

        UserActivityLogs\create_from_request @, {
          user_id: @current_user.id
          action: "account.revoke_api_key"
          source: "web"
          data: {
            key: @key.key
          }
        }

        redirect_to: @url_for "user_settings.api_keys"
    }
  }

  "/api/tool_version": =>
    config = require"lapis.config".get!
    json: { version: config.tool_version }

  -- Get status of key
  "/api/1/:key/status": api_request =>
    json: { user_id: @current_user.id, created_at: @key.created_at }

  -- NOT USED
  "/api/1/:key/modules": api_request =>
    json: { modules: @current_user\get_modules! }

  "/api/1/:key/check_rockspec": api_request =>
    assert_valid @params, {
      { "package", exists: true, type: "string" }
      { "version", exists: true, type: "string" }
    }

    module = Modules\find user_id: @current_user.id, name: @params.package\lower!
    version = if module
      Versions\find module_id: module.id, version_name: @params.version\lower!

    json: { :module, :version }

  "/api/1/:key/upload": api_request =>
    module, version, is_new = handle_rockspec_upload @

    import UserActivityLogs from require "models"

    UserActivityLogs\create_from_request @, {
      user_id: @current_user.id
      action: if is_new then "module.create" else "module.add_version"
      source: "api"
      object_type: "module"
      object_id: module.id
      data: {
        version_id: version.id
        version_name: version.version_name
      }
    }

    @key\increment_actions!

    manifest_modules = ManifestModules\select "where module_id = ?", module.id
    Manifests\include_in manifest_modules, "manifest_id"

    manifests = [m.manifest for m in *manifest_modules]
    module_url = @build_url @url_for "module", user: @current_user, :module
    json: { :module, :version, :module_url, :manifests, :is_new }

  "/api/1/:key/upload_rock/:version_id": api_request =>
    assert_valid @params, {
      {"version_id", is_integer: true}
    }

    @version = Versions\find(id: @params.version_id)

    unless @version
      return {
        status: 404
        json: { errors: {"invalid version"} }
      }

    @module = Modules\find id: @version.module_id
    rock = assert_error handle_rock_upload @

    import UserActivityLogs from require "models"

    UserActivityLogs\create_from_request @, {
      user_id: @current_user.id
      action: "module.version.upload_rock"
      source: "api"
      object_type: "version"
      object_id: @version.id
      data: {
        rock_id: rock.id
        rock_revision: rock.revision
        rock_arch: rock.arch
      }
    }

    @key\increment_actions!

    module_url = @build_url @url_for "module", user: @current_user, module: @module
    json: { :rock, :module_url }

  -- Callback endpoint for audit results from GitHub Actions
  -- Authenticated via HMAC signature, not API key
  "/api/audit-callback": capture_errors_json respond_to {
    POST: =>
      config = require("lapis.config").get!
      hmac_secret = config.audit_hmac_secret

      unless hmac_secret
        return status: 500, json: { error: "audit_hmac_secret not configured" }

      -- Get signature from header
      signature_header = @req.headers["x-signature"]
      unless signature_header
        return status: 401, json: { error: "missing X-Signature header" }

      expected_prefix = "sha256="
      unless signature_header\sub(1, #expected_prefix) == expected_prefix
        return status: 401, json: { error: "invalid signature format" }

      provided_signature = signature_header\sub(#expected_prefix + 1)

      -- Get raw request body for HMAC verification
      ngx.req.read_body!
      body = ngx.req.get_body_data!

      unless body
        return status: 400, json: { error: "missing request body" }

      -- Compute expected signature
      openssl_hmac = require "openssl.hmac"
      hmac = openssl_hmac.new hmac_secret, "sha256"
      hmac\update body
      expected_signature = hmac\final!\gsub ".", (c) -> string.format "%02x", string.byte c

      if #provided_signature != #expected_signature
        return status: 401, json: { error: "invalid signature" }

      mismatch = 0
      for i = 1, #expected_signature
        mismatch = bit.bor mismatch, bit.bxor(
          string.byte(provided_signature, i),
          string.byte(expected_signature, i)
        )

      if mismatch != 0
        return status: 401, json: { error: "invalid signature" }

      -- Parse body and update audit
      import from_json from require "lapis.util"
      params = from_json body

      audit_id = tonumber params.audit_id
      unless audit_id
        return status: 400, json: { error: "missing audit_id" }

      audit = FileAudits\find audit_id
      unless audit
        return status: 404, json: { error: "audit not found" }

      external_id = params.external_id

      switch params.status
        when "completed"
          unless audit\verify_external_id external_id
            return status: 400, json: { error: "external_id mismatch, dropping event" }
          audit\mark_complete params.result_data
        when "failed"
          unless audit\verify_external_id external_id
            return status: 400, json: { error: "external_id mismatch, dropping event" }
          audit\mark_failed params.error_message or "unknown error"
        when "running"
          audit\mark_started external_id
        else
          return status: 400, json: { error: "invalid status" }

      json: { success: true }
  }

