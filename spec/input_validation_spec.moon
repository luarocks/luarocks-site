import
  is_valid_manifest_string
  parse_rockspec
  parse_rock_fname
  from require "helpers.uploaders"

describe "input validation", ->
  describe "is_valid_manifest_string", ->
    it "accepts valid alphanumeric strings", ->
      assert.truthy is_valid_manifest_string "hello"
      assert.truthy is_valid_manifest_string "Hello123"
      assert.truthy is_valid_manifest_string "test-module"
      assert.truthy is_valid_manifest_string "test_module"
      assert.truthy is_valid_manifest_string "test.module"
      assert.truthy is_valid_manifest_string "lua-cjson"
      assert.truthy is_valid_manifest_string "1.2.3-1"
      assert.truthy is_valid_manifest_string "linux-x86_64"

    it "rejects empty strings", ->
      assert.falsy is_valid_manifest_string ""

    it "rejects too long strings", ->
      assert.falsy is_valid_manifest_string "hi"\rep 400

    it "rejects nil", ->
      assert.falsy is_valid_manifest_string nil

    it "rejects strings with spaces", ->
      assert.falsy is_valid_manifest_string "hello world"
      assert.falsy is_valid_manifest_string " leading"
      assert.falsy is_valid_manifest_string "trailing "

    it "rejects strings with backslashes", ->
      assert.falsy is_valid_manifest_string [[test\value]]
      assert.falsy is_valid_manifest_string [[test\"]]
      assert.falsy is_valid_manifest_string [[x\";injected=true--]]

    it "rejects strings with quotes", ->
      assert.falsy is_valid_manifest_string [[test"value]]
      assert.falsy is_valid_manifest_string [[test'value]]

    it "rejects strings with newlines", ->
      assert.falsy is_valid_manifest_string "test\nvalue"
      assert.falsy is_valid_manifest_string "test\rvalue"

    it "rejects strings with brackets", ->
      assert.falsy is_valid_manifest_string "test[value"
      assert.falsy is_valid_manifest_string "test]value"
      assert.falsy is_valid_manifest_string "test[[value"

    it "rejects strings with other special characters", ->
      assert.falsy is_valid_manifest_string "test@value"
      assert.falsy is_valid_manifest_string "test;value"
      assert.falsy is_valid_manifest_string "test=value"
      assert.falsy is_valid_manifest_string "test{value"
      assert.falsy is_valid_manifest_string "test}value"
      assert.falsy is_valid_manifest_string "test(value"
      assert.falsy is_valid_manifest_string "test)value"

  describe "parse_rockspec", ->
    it "accepts valid rockspec", ->
      rockspec = [[
        package = "my-module"
        version = "1.0-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.truthy spec
      assert.same "my-module", spec.package
      assert.same "1.0-1", spec.version

    it "rejects package name with space", ->
      rockspec = [[
        package = "test module"
        version = "1.0-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects package name with at sign", ->
      rockspec = [[
        package = "test@module"
        version = "1.0-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects package name with semicolon", ->
      rockspec = [[
        package = "test;module"
        version = "1.0-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects package name with equals", ->
      rockspec = [[
        package = "test=module"
        version = "1.0-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects version with space", ->
      rockspec = [[
        package = "mymodule"
        version = "1.0 -1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects version with at sign", ->
      rockspec = [[
        package = "mymodule"
        version = "@version@-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

    it "rejects version with brackets", ->
      rockspec = [[
        package = "mymodule"
        version = "1.0[test]-1"
      ]]
      spec, err = parse_rockspec rockspec
      assert.falsy spec
      assert.truthy err\match "invalid characters"

  describe "parse_rock_fname", ->
    it "accepts valid rock filename", ->
      result, err = parse_rock_fname "mymodule", "mymodule-1.0-1.linux-x86_64.rock"
      assert.truthy result
      assert.same "1.0-1", result.version
      assert.same "linux-x86_64", result.arch

    it "accepts common arch values", ->
      for arch in *{"src", "all", "linux-x86_64", "macosx-x86_64", "win32-x86"}
        result, err = parse_rock_fname "mod", "mod-1.0-1.#{arch}.rock"
        assert.truthy result, "should accept arch: #{arch}"
        assert.same arch, result.arch

    it "rejects arch with backslash", ->
      result, err = parse_rock_fname "mod", [[mod-1.0-1.x\.rock]]
      assert.falsy result

    it "rejects arch with injection payload", ->
      result, err = parse_rock_fname "mod", "mod-1.0-1.x\"inject.rock"
      assert.falsy result

    it "rejects arch with space", ->
      result, err = parse_rock_fname "mod", "mod-1.0-1.linux x86.rock"
      assert.falsy result

    it "rejects arch with semicolon", ->
      result, err = parse_rock_fname "mod", "mod-1.0-1.x;evil.rock"
      assert.falsy result

    it "rejects arch with equals sign", ->
      result, err = parse_rock_fname "mod", "mod-1.0-1.x=evil.rock"
      assert.falsy result

    it "rejects arch with brackets", ->
      result, err = parse_rock_fname "mod", "mod-1.0-1.x[evil].rock"
      assert.falsy result
