factory = require "spec.factory"

describe "models.versions", ->
  import
    Manifests
    Modules
    Users
    Versions
    Rocks
    Dependencies
    from require "spec.models"

  it "allowed_to_edit only retrns true for owner/admin", ->
    v = factory.Versions!
    assert.falsy v\allowed_to_edit nil
    assert.truthy v\allowed_to_edit v\get_module!\get_user!
    assert.falsy v\allowed_to_edit factory.Users!
    assert.truthy v\allowed_to_edit factory.Users flags: 1

  describe "update_dependencies", ->
    it "extracts dependency name when version operator is attached without space", ->
      v = factory.Versions!
      v\update_dependencies {
        dependencies: {
          "lua-zlib>=0.0.1"
        }
      }

      deps = Dependencies\select "where version_id = #{v.id}"
      assert.same 1, #deps
      assert.same "lua-zlib", deps[1].dependency_name
      assert.same "lua-zlib>=0.0.1", deps[1].dependency

    it "extracts dependency name when version operator is attached with trailing space", ->
      v = factory.Versions!
      v\update_dependencies {
        dependencies: {
          "lua-zlib>= 0.0.1"
        }
      }

      deps = Dependencies\select "where version_id = #{v.id}"
      assert.same 1, #deps
      assert.same "lua-zlib", deps[1].dependency_name
      assert.same "lua-zlib>= 0.0.1", deps[1].dependency

    it "extracts dependency name when version operator has spaces on both sides", ->
      v = factory.Versions!
      v\update_dependencies {
        dependencies: {
          "lua-zlib >= 0.0.1"
        }
      }

      deps = Dependencies\select "where version_id = #{v.id}"
      assert.same 1, #deps
      assert.same "lua-zlib", deps[1].dependency_name
      assert.same "lua-zlib >= 0.0.1", deps[1].dependency

  describe "parse_version", ->
    it "returns version constraint when operator is attached without space", ->
      dep = Dependencies\create {
        version_id: factory.Versions!.id
        dependency_name: "lua-zlib"
        dependency: "lua-zlib>=0.0.1"
      }
      assert.same ">=0.0.1", dep\parse_version!

    it "returns version constraint when operator has trailing space", ->
      dep = Dependencies\create {
        version_id: factory.Versions!.id
        dependency_name: "lua-zlib"
        dependency: "lua-zlib>= 0.0.1"
      }
      assert.same ">= 0.0.1", dep\parse_version!

    it "returns version constraint when spaces on both sides", ->
      dep = Dependencies\create {
        version_id: factory.Versions!.id
        dependency_name: "lua-zlib"
        dependency: "lua-zlib >= 0.0.1"
      }
      assert.same ">= 0.0.1", dep\parse_version!

    it "returns nil when there is no version constraint", ->
      dep = Dependencies\create {
        version_id: factory.Versions!.id
        dependency_name: "lua-zlib"
        dependency: "lua-zlib"
      }
      assert.is_nil dep\parse_version!


