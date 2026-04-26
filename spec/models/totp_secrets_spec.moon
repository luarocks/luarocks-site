
factory = require "spec.factory"

describe "models.totp_secrets", ->
  import use_test_env from require "lapis.spec"
  use_test_env!

  import
    Users
    TotpSecrets
    TotpScratchcodes
    from require "spec.models"

  totp = require "helpers.totp"

  it "create_for stores the secret and returns plaintext scratchcodes", ->
    user = factory.Users!
    secret = totp.generate_secret!

    instance, codes = TotpSecrets\create_for user, secret

    assert.truthy instance
    assert.same secret, instance.secret
    assert.same 5, #codes
    for code in *codes
      assert.same 8, #code

  it "stores scratchcodes as bcrypt hashes (not plaintext)", ->
    user = factory.Users!
    _, plaintext_codes = TotpSecrets\create_for user, totp.generate_secret!

    rows = TotpScratchcodes\for_user user
    assert.same 5, #rows

    plaintext_set = {code, true for code in *plaintext_codes}
    for row in *rows
      assert.truthy row.secret\match("^%$2[aby]%$"), "expected bcrypt hash, got: #{row.secret}"
      assert.falsy plaintext_set[row.secret]

  it "verify_and_consume returns true once and false on the second call", ->
    user = factory.Users!
    _, codes = TotpSecrets\create_for user, totp.generate_secret!

    one_code = codes[1]
    assert.truthy TotpScratchcodes\verify_and_consume user, one_code
    assert.falsy TotpScratchcodes\verify_and_consume user, one_code

  it "verify_and_consume rejects a wrong code", ->
    user = factory.Users!
    TotpSecrets\create_for user, totp.generate_secret!

    assert.falsy TotpScratchcodes\verify_and_consume user, "00000000"

  it "removes scratchcodes when secret is deleted", ->
    user = factory.Users!
    secret_row, _ = TotpSecrets\create_for user, totp.generate_secret!

    assert.same 5, #TotpScratchcodes\for_user user
    secret_row\delete!
    assert.same 0, #TotpScratchcodes\for_user user

  it "creates a fresh set of scratchcodes when called again (regenerate)", ->
    user = factory.Users!
    secret = totp.generate_secret!

    _, first_codes = TotpSecrets\create_for user, secret
    _, second_codes = TotpSecrets\create_for user, secret

    assert.same 5, #TotpScratchcodes\for_user user

    -- old codes no longer work
    assert.falsy TotpScratchcodes\verify_and_consume user, first_codes[1]
    assert.truthy TotpScratchcodes\verify_and_consume user, second_codes[1]
