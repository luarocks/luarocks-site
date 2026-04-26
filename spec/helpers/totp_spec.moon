
describe "helpers.totp", ->
  totp = require "helpers.totp"

  it "generates a base32-encoded secret", ->
    secret = totp.generate_secret!
    assert.same "string", type(secret)
    assert.truthy #secret >= 16
    assert.truthy secret\match "^[A-Z2-7=]+$"

  it "generates 5 8-digit scratchcodes by default", ->
    codes = totp.generate_scratchcodes!
    assert.same 5, #codes
    for code in *codes
      assert.same "string", type(code)
      assert.same 8, #code
      assert.truthy code\match "^[0-9]+$"
      assert.truthy tonumber(code) >= 10000000

  it "round-trips generate_code through check_code", ->
    secret = totp.generate_secret!
    code = totp.generate_code secret
    assert.truthy totp.check_code secret, code

  it "rejects an invalid code", ->
    secret = totp.generate_secret!
    assert.falsy totp.check_code secret, "000000"

  it "rejects an empty code", ->
    secret = totp.generate_secret!
    assert.falsy totp.check_code secret, ""
    assert.falsy totp.check_code secret, nil

  it "matches a code from a previous time interval within the window", ->
    secret = totp.generate_secret!
    earlier = totp.time_interval! - 1
    code = totp.generate_code secret, earlier
    assert.truthy totp.check_code secret, code

  it "rejects a code from outside the time window", ->
    secret = totp.generate_secret!
    way_earlier = totp.time_interval! - 10
    code = totp.generate_code secret, way_earlier
    assert.falsy totp.check_code secret, code

  it "produces an otpauth URL", ->
    secret = "JBSWY3DPEHPK3PXP"
    url = totp.get_url secret, "alice"
    assert.same "otpauth://totp/alice%40luarocks%2eorg?secret=JBSWY3DPEHPK3PXP&issuer=luarocks%2eorg", url

  it "escapes otpauth URL components", ->
    secret = "JBSWY3DPEHPK3PXP"
    url = totp.get_url secret, "alice@example.com", "LuaRocks & Co"
    assert.same "otpauth://totp/alice%40example%2ecom%40LuaRocks%20%26%20Co?secret=JBSWY3DPEHPK3PXP&issuer=LuaRocks%20%26%20Co", url
