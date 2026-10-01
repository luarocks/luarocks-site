factory = require "spec.factory"

describe "models.versions", ->
  import
    Manifests
    Modules
    Users
    Versions
    Rocks
    from require "spec.models"

  it "allowed_to_edit only retrns true for owner/admin", ->
    v = factory.Versions!
    assert.falsy v\allowed_to_edit nil
    assert.truthy v\allowed_to_edit v\get_module!\get_user!
    assert.falsy v\allowed_to_edit factory.Users!
    assert.truthy v\allowed_to_edit factory.Users flags: 1



  describe "dependencies", ->
    import Dependencies from require "spec.models"

    it "parses dependency strings", ->
      parse = (str) -> {Dependencies\parse_dependency str}

      assert.same {"foo", ">= 1.0"}, parse "foo >= 1.0"
      assert.same {"foo", ">=1.0"}, parse "foo>=1.0"
      assert.same {"foo", "==0.0.1"}, parse "foo==0.0.1"
      assert.same {"foo", ">= 1.0, < 2.0"}, parse "  foo >= 1.0, < 2.0  "
      assert.same {"foo"}, parse "foo"
      assert.same {"foo"}, parse "Foo"
      assert.same {"ns/foo", ">=1"}, parse "ns/foo>=1"
      assert.same {}, parse ">= 1.0"

    it "updates dependencies from spec", ->
      v = factory.Versions!
      v\update_dependencies {
        dependencies: {
          "lua>=5.1"
          "Foo>=0.0.1"
          "bar == 1.0"
          "baz"
          "foo >= 2.0"
        }
      }

      deps = {d.dependency_name, d\parse_version! or false for d in *v\get_dependencies!}
      assert.same {
        lua: ">=5.1"
        foo: ">=0.0.1"
        bar: "== 1.0"
        baz: false
      }, deps

    it "sets lua_version without a space before the operator", ->
      v = factory.Versions!
      v\update_from_spec dependencies: {"foo", "lua>=5.1"}
      assert.same "lua>=5.1", v.lua_version
