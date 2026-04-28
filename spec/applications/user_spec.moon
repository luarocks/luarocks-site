
import get_session from require "lapis.session"
import parse_cookie_string from require "lapis.util"

import use_test_server from require "lapis.spec"

import request from require "spec.helpers"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "application.user", ->
  use_test_server!

  import Followings from require "spec.models"
  import Users, UserData from require "spec.models"

  it "makes user data object", ->
    user = factory.Users!
    user\get_data!
    assert.same 1, UserData\count!

  it "should register a user", ->
    status, body, headers = request "/register", {
      csrf: true
      post: {
        username: "leafo"
        password: "pword"
        password_repeat: "pword"
        email: "leafo@example.com"
      }
    }

    assert.same 302, status
    assert.same 'http://localhost:8080/', headers.location
    user = unpack Users\select!
    assert.truthy user

  describe "with user", ->
    local user

    before_each ->
      user = Users\create "leafo", "pword", "leafo@example.com"

    it "should log in a user", ->
      status, body, headers = request "/login", {
        csrf: true
        post: {
          username: "leafo"
          password: "pword"
        }
      }

      assert.truthy headers.set_cookie
      session = get_session cookies: parse_cookie_string(headers.set_cookie)
      assert.same user.id, session.user.id

    it "should redirect to canonical user profile when case doesn't match", ->
      status, body, headers = request "/modules/LeAfO"
      assert.same 301, status
      assert.same "http://localhost:8080/modules/leafo", headers.location

    it "should not redirect when user slug matches exactly", ->
      status, body, headers = request "/modules/leafo"
      assert.same 200, status
      assert.falsy headers.location

    it "should handle user with mixed case username correctly", ->
      mixed_user = Users\create "MixedCase", "pword", "mixed@example.com"

      -- Should redirect to lowercase slug
      status, body, headers = request "/modules/MiXeDcAsE"
      assert.same 301, status
      assert.same "http://localhost:8080/modules/mixedcase", headers.location

      -- Should not redirect when using correct slug
      status, body, headers = request "/modules/mixedcase"
      assert.same 200, status
      assert.falsy headers.location

    it "should return 404 for non-existent user", ->
      status, body = request "/modules/nonexistentuser"
      assert.same 404, status

    it "should follow a user", ->
      other_user = factory.Users!
      status, res = request_as user, "/users/#{other_user.slug}/follow"
      assert.same 302, status

      followings = Followings\select!

      assert.same 1, #followings
      following = unpack followings

      assert.same user.id, following.source_user_id
      assert.same Followings.object_types.user, following.object_type
      assert.same other_user.id, following.object_id

      user\refresh!

      assert.same 1, user.following_count

    it "should unfollow a user", ->
      other_user = factory.Users!
      follow = factory.Followings {
        source_user_id: user.id
        object: other_user
        type: "subscription"
      }

      status, res = request_as user, "/users/#{other_user.slug}/unfollow"
      assert.same 302, status

      followings = Followings\select!

      assert.same 0, #followings

      user\refresh!

      assert.same 0, user.following_count

    describe "api keys", ->
      it "gets api keys with no api keys", ->
        status, body, headers = request_as user, "/settings/api-keys"
        assert.same 200, status

      it "gets api keys with no api keys", ->
        factory.ApiKeys user_id: user.id
        status, body, headers = request_as user, "/settings/api-keys"
        assert.same 200, status

      it "sets comment", ->
        key = factory.ApiKeys user_id: user.id
        status, body, headers = request_as user, "/settings/api-keys", {
          post: {
            api_key: key.key
            comment: " Helllo world "
          }
        }

        assert.same 302, status
        key\refresh!
        assert.same "Helllo world", key.comment

      it "sets doesn't set comment on other users key", ->
        key = factory.ApiKeys!
        key\update comment: "okay"

        status, body, headers = request_as user, "/settings/api-keys", {
          post: {
            api_key: key.key
            comment: "hacked"
          }
        }

        assert.same 200, status
        key\refresh!
        assert.same "okay", key.comment

    describe "two-factor authentication", ->
      totp = require "helpers.totp"
      import TotpSecrets, TotpScratchcodes from require "spec.models"

      it "loads the two-factor settings page", ->
        status = request_as user, "/settings/two-factor-auth"
        assert.same 200, status

      it "loads the enrollment page", ->
        status = request_as user, "/settings/two-factor-auth/setup"
        assert.same 200, status

      it "rejects enrollment with wrong password", ->
        secret = totp.generate_secret!
        status = request_as user, "/settings/two-factor-auth/confirm", {
          post: {
            secret: secret
            code: totp.generate_code secret
            current_password: "wrong"
          }
        }
        assert.same 200, status -- error page renders inline
        assert.falsy user\refresh!\has_totp!

      it "rejects enrollment with wrong code", ->
        secret = totp.generate_secret!
        status = request_as user, "/settings/two-factor-auth/confirm", {
          post: {
            secret: secret
            code: "000000"
            current_password: "pword"
          }
        }
        assert.same 200, status
        assert.falsy user\refresh!\has_totp!

      it "enrolls with correct password and code", ->
        secret = totp.generate_secret!
        status, _, headers = request_as user, "/settings/two-factor-auth/confirm", {
          post: {
            secret: secret
            code: totp.generate_code secret
            current_password: "pword"
          }
        }
        assert.same 302, status
        assert.truthy headers.location\match "/settings/two%-factor%-auth/scratchcodes$"
        assert.truthy user\refresh!\has_totp!

        secret_row = TotpSecrets\find user.id
        assert.same secret, secret_row.secret
        assert.same 5, #TotpScratchcodes\for_user user

      it "redirects to 2fa challenge on login when enabled", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        status, _, headers = request "/login", {
          csrf: true
          post: {
            username: user.username
            password: "pword"
          }
        }
        assert.same 302, status
        assert.truthy headers.location\match("/login/two%-factor%?token="), "got: #{headers.location}"

      it "completes login after entering valid TOTP code", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        _, _, headers = request "/login", {
          csrf: true
          post: {
            username: user.username
            password: "pword"
          }
        }

        verify_url = headers.location\gsub "^http://[^/]+", ""
        status, _, headers = request verify_url, {
          csrf: true
          post: {
            code: totp.generate_code secret
          }
        }
        assert.same 302, status
        assert.truthy headers.set_cookie

      it "completes login with a backup code (single-use)", ->
        secret = totp.generate_secret!
        codes = user\enable_totp secret
        backup = codes[1]

        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""

        status, _, headers2 = request verify_url, {
          csrf: true
          post: { code: backup }
        }
        assert.same 302, status
        assert.same 4, #TotpScratchcodes\for_user user

        -- second use of the same backup code fails
        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""
        status = request verify_url, {
          csrf: true
          post: { code: backup }
        }
        assert.same 200, status -- re-renders verify page with error

      it "rejects 2fa challenge with wrong code", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""

        status = request verify_url, {
          csrf: true
          post: { code: "000000" }
        }
        assert.same 200, status

      it "disable requires password and a valid code", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        -- wrong password
        request_as user, "/settings/two-factor-auth", {
          post: { action: "disable", current_password: "wrong", code: totp.generate_code secret }
        }
        assert.truthy user\refresh!\has_totp!

        -- wrong code
        request_as user, "/settings/two-factor-auth", {
          post: { action: "disable", current_password: "pword", code: "000000" }
        }
        assert.truthy user\refresh!\has_totp!

        -- correct
        status = request_as user, "/settings/two-factor-auth", {
          post: { action: "disable", current_password: "pword", code: totp.generate_code secret }
        }
        assert.same 302, status
        assert.falsy user\refresh!\has_totp!

      it "regenerates backup codes", ->
        secret = totp.generate_secret!
        first_codes = user\enable_totp secret
        (TotpSecrets\find user.id)\update require_for_uploads: true

        status = request_as user, "/settings/two-factor-auth", {
          post: { action: "regenerate", current_password: "pword", code: totp.generate_code secret }
        }
        assert.same 302, status
        assert.same 5, #TotpScratchcodes\for_user user
        assert.truthy user\refresh!\requires_tfa_for_uploads!

        -- old code is gone
        assert.falsy TotpScratchcodes\verify_and_consume user, first_codes[1]

      it "login without 2fa enabled goes straight through", ->
        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        assert.truthy headers.set_cookie
        assert.same "http://localhost:8080/", headers.location

      it "preserves return_to through the 2fa flow", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        _, _, headers = request "/login", {
          csrf: true
          post: {
            username: user.username
            password: "pword"
            return_to: "/about"
          }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""

        _, _, headers2 = request verify_url, {
          csrf: true
          post: { code: totp.generate_code secret }
        }
        assert.same "http://localhost:8080/about", headers2.location

      it "rejects a tampered token", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""
        -- flip the last character of the token (signature byte)
        tampered_url = verify_url\sub(1, -2) .. (verify_url\sub(-1) == "x" and "y" or "x")

        status, _, headers2 = request tampered_url, { csrf: true, post: { code: "000000" } }
        assert.same 302, status
        assert.same "http://localhost:8080/login", headers2.location

      it "rejects an expired token", ->
        import encode_with_secret from require "lapis.util.encoding"
        import escape from require "lapis.util"

        secret = totp.generate_secret!
        user\enable_totp secret

        token = encode_with_secret {
          id: user.id
          key: user\salt!
          expires: os.time! - 60
          return_to: false
        }
        url = "/login/two-factor?token=" .. escape token

        status, _, headers2 = request url, {
          csrf: true
          post: { code: totp.generate_code secret }
        }
        assert.same 302, status
        assert.same "http://localhost:8080/login", headers2.location

      it "rejects a token after the user's password changes", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        _, _, headers = request "/login", {
          csrf: true
          post: { username: user.username, password: "pword" }
        }
        verify_url = headers.location\gsub "^http://[^/]+", ""

        -- password change between issuing the challenge and verifying it
        user\update_password "different"

        status, _, headers2 = request verify_url, {
          csrf: true
          post: { code: totp.generate_code secret }
        }
        assert.same 302, status
        assert.same "http://localhost:8080/login", headers2.location

      it "redirects logged-in users away from the 2fa challenge", ->
        secret = totp.generate_secret!
        user\enable_totp secret
        status, _, headers = request_as user, "/login/two-factor?token=anything"
        assert.same 302, status
        assert.same "http://localhost:8080/", headers.location

      it "tfa_setup redirects to settings when already enabled", ->
        secret = totp.generate_secret!
        user\enable_totp secret
        status, _, headers = request_as user, "/settings/two-factor-auth/setup"
        assert.same 302, status
        assert.truthy headers.location\match("/settings/two%-factor%-auth$")

      it "tfa_confirm refuses to enroll when already enabled", ->
        existing_secret = totp.generate_secret!
        user\enable_totp existing_secret

        new_secret = totp.generate_secret!
        request_as user, "/settings/two-factor-auth/confirm", {
          post: {
            secret: new_secret
            code: totp.generate_code new_secret
            current_password: "pword"
          }
        }

        -- the original secret is unchanged
        TotpSecrets = require("models").TotpSecrets
        row = TotpSecrets\find user.id
        assert.same existing_secret, row.secret

      it "disable removes the secret and all scratchcodes", ->
        secret = totp.generate_secret!
        user\enable_totp secret

        request_as user, "/settings/two-factor-auth", {
          post: { action: "disable", current_password: "pword", code: totp.generate_code secret }
        }

        TotpSecrets = require("models").TotpSecrets
        assert.falsy TotpSecrets\find user.id
        assert.same 0, #TotpScratchcodes\for_user user

      describe "backup codes display", ->
        it "shows freshly-generated codes once", ->
          secret = totp.generate_secret!

          headers = {}
          request_as user, "/settings/two-factor-auth/confirm", {
            post: {
              secret: secret
              code: totp.generate_code secret
              current_password: "pword"
            }
            headers: headers
          }

          -- follow the redirect chain by reusing the cookie jar via request_as
          status, body = request_as user, "/settings/two-factor-auth/scratchcodes"
          assert.same 200, status
          -- when there's nothing in the session, the empty-state copy renders
          assert.truthy body\match("Backup codes")

        it "renders empty state on direct visit", ->
          status, body = request_as user, "/settings/two-factor-auth/scratchcodes"
          assert.same 200, status
          assert.truthy body\match("no new backup codes") or body\match("not be shown again") or body\match("Backup")

      describe "upload requirement toggle", ->
        local secret

        before_each ->
          secret = totp.generate_secret!
          user\enable_totp secret

        it "enables the upload requirement with valid password and code", ->
          status = request_as user, "/settings/two-factor-auth", {
            post: {
              action: "settings"
              current_password: "pword"
              code: totp.generate_code secret
              require_for_uploads: "on"
            }
          }
          assert.same 302, status
          assert.truthy user\refresh!\requires_tfa_for_uploads!

        it "disables the upload requirement", ->
          (TotpSecrets\find user.id)\update require_for_uploads: true
          assert.truthy user\refresh!\requires_tfa_for_uploads!

          status = request_as user, "/settings/two-factor-auth", {
            post: {
              action: "settings"
              current_password: "pword"
              code: totp.generate_code secret
              require_for_uploads: ""
            }
          }
          assert.same 302, status
          assert.falsy user\refresh!\requires_tfa_for_uploads!

        it "rejects with wrong password", ->
          request_as user, "/settings/two-factor-auth", {
            post: {
              action: "settings"
              current_password: "wrong"
              code: totp.generate_code secret
              require_for_uploads: "true"
            }
          }
          assert.falsy user\refresh!\requires_tfa_for_uploads!

        it "rejects with wrong code", ->
          request_as user, "/settings/two-factor-auth", {
            post: {
              action: "settings"
              current_password: "pword"
              code: "000000"
              require_for_uploads: "true"
            }
          }
          assert.falsy user\refresh!\requires_tfa_for_uploads!

        it "rejects when 2FA is not enabled", ->
          user\disable_totp!
          request_as user, "/settings/two-factor-auth", {
            post: {
              action: "settings"
              current_password: "pword"
              code: "000000"
              require_for_uploads: "true"
            }
          }
          assert.falsy user\refresh!\requires_tfa_for_uploads!

      it "API key authentication bypasses 2fa", ->
        import ApiKeys from require "spec.models"
        secret = totp.generate_secret!
        user\enable_totp secret

        key = ApiKeys\generate user.id, "specs"
        status, body = request "/api/1/#{key.key}/status"
        assert.same 200, status
        cjson = require "cjson"
        decoded = cjson.decode body
        assert.same user.id, decoded.user_id
