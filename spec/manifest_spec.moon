import use_test_server from require "lapis.spec"

import
  ManifestModules
  Manifests
  Modules
  Rocks
  Users
  Versions
  from require "models"

import truncate_tables from require "lapis.spec.db"

import request, request_as from require "spec.helpers"

factory = require "spec.factory"

parse_manifest = (text) ->
  fn = assert loadstring text
  m = {}
  setfenv fn, m
  assert pcall(fn)
  m

shell_escape = (str) ->
  str\gsub "'", "''"

request_manifest = (url) ->
  status, body = request url
  assert.same 200, status
  parse_manifest body

should_load_manifest = (url, fn) ->
  it "should load manifest #{url}", ->
    m = request_manifest url
    fn m if fn

should_load_zip_manifest = (url, fn) ->
  it "should zip load manifest #{url}", ->
    status, body = request url
    assert.same 200, status
    assert body\match("^PK"), "not valid zip"

    import encode_base64 from require "lapis.util.encoding"
    f = io.popen "echo '#{shell_escape encode_base64 body}' | base64 -d | funzip", "r"
    unzipped = f\read "*a"
    m = parse_manifest unzipped
    fn m if fn

describe "moonrocks", ->
  use_test_server!

  local root

  before_each ->
    truncate_tables Manifests, ManifestModules, Users, Modules, Rocks, Versions
    root = Manifests\create "root", true

  is_empty_manifest = (m) ->
    assert.same {
      repository: {}
      commands: {}
      modules: {}
    }, m

  for v in *{"", "-5.1", "-5.2", "-5.3"}
    should_load_manifest "/manifest#{v}", is_empty_manifest
    should_load_manifest "/dev/manifest#{v}", is_empty_manifest

    if v != ""
      should_load_zip_manifest "/manifest#{v}.zip"
      should_load_zip_manifest "/dev/manifest#{v}.zip"

  has_module = (manifest, mod) ->
    assert manifest.repository[mod.name],
      "manifest should have module"

  describe "with a module", ->
    local mod

    before_each ->
      mod = factory.Modules!
      ManifestModules\create root, mod

    should_load_manifest "/manifest", is_empty_manifest

    describe "with regular version", ->
      local version

      before_each ->
        version = factory.Versions module_id: mod.id

      -- no lua version, should have module in versioned
      should_load_manifest "/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifest-5.2", (m) -> has_module m, mod

      should_load_zip_manifest "/manifest-5.1.zip", (m) -> has_module m, mod
      should_load_zip_manifest "/manifest-5.2.zip", (m) -> has_module m, mod

      should_load_manifest "/dev/manifest", is_empty_manifest

      it "should do HEAD", ->
        status, body, headers = request "/manifest", {
          method: "HEAD"
        }

        assert.same 200, status
        assert.same "", body
        assert.truthy headers["Last-Modified"]

    describe "with development version", ->
      local version

      before_each ->
        version = factory.Versions module_id: mod.id, development: true

      should_load_manifest "/manifest", is_empty_manifest
      should_load_manifest "/dev/manifest", (m) -> has_module m, mod
      should_load_manifest "/dev/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/dev/manifest-5.2", (m) -> has_module m, mod

      should_load_zip_manifest "/dev/manifest-5.1.zip", (m) -> has_module m, mod
      should_load_zip_manifest "/dev/manifest-5.2.zip", (m) -> has_module m, mod

    describe "with versioned version", ->
      local version

      before_each ->
        version = factory.Versions module_id: mod.id, lua_version: "lua >= 5.1, < 5.2"

      -- no lua version, should have module in versioned
      should_load_manifest "/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifest-5.2", is_empty_manifest

      should_load_manifest "/dev/manifest", is_empty_manifest


    describe "with many versions", ->
      versions = {}

      before_each ->
        v = factory.Versions {
          module_id: mod.id
          version_name: "1-1"
          lua_version: "lua >= 5.1, < 5.2"
        }

        factory.Rocks {
          version_id: v.id
          arch: "win99"
        }

        factory.Versions {
          module_id: mod.id
          version_name: "2-1"
        }

        factory.Versions {
          module_id: mod.id
          version_name: "git-1"
          development: true
        }

      should_load_manifest "/manifest", (m) ->
        assert.same {
          [mod.name]: {
            ["1-1"]: { { arch: "rockspec" }, { arch: "win99" } }
            ["2-1"]: { { arch: "rockspec" } }
          }
        }, m.repository

      should_load_manifest "/manifest-5.1", (m) ->
        assert.same {
          [mod.name]: {
            ["1-1"]: { { arch: "rockspec" }, { arch: "win99" } }
            ["2-1"]: { { arch: "rockspec" } }
          }
        }, m.repository

      should_load_manifest "/manifest-5.2", (m) ->
        assert.same {
          [mod.name]: {
            ["2-1"]: { { arch: "rockspec" } }
          }
        }, m.repository


      should_load_manifest "/dev/manifest", (m) ->
        assert.same {
          [mod.name]: {
            ["git-1"]: { { arch: "rockspec" } }
          }
        }, m.repository

      should_load_manifest "/dev/manifest-5.1", (m) ->
        assert.same {
          [mod.name]: {
            ["git-1"]: { { arch: "rockspec" } }
          }
        }, m.repository


  describe "with many modules", ->
    before_each ->
      for i=1,3
        mod = factory.Modules!
        factory.ManifestModules manifest_id: root.id, module_id: mod.id

      for i=1,2
        mod = factory.Modules has_dev_version: true
        factory.ManifestModules manifest_id: root.id, module_id: mod.id

    it "should show manifest", ->
      status, res = request "/m/root"
      assert.same 200, status

    it "should show development only manifest", ->
      status, res = request "/m/root/development-only"
      assert.same 200, status

  describe "user manifest", ->
    local user

    before_each ->
      user = factory.Users username: "tester"

    should_load_manifest "/manifests/tester/manifest", is_empty_manifest
    should_load_manifest "/manifests/tester/manifest-5.1", is_empty_manifest
    should_load_manifest "/manifests/tester/manifest-5.2", is_empty_manifest

    describe "with regular version", ->
      local mod, version

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id


      should_load_manifest "/manifests/tester/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.2", (m) -> has_module m, mod

    -- development versions show up by default in user manifest at the moment
    describe "with development version", ->
      local mod, version

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id, development: true

      should_load_manifest "/manifests/tester/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.2", (m) -> has_module m, mod


  describe "adding and removing modules", ->
    local user, mod, add_url, remove_url

    before_each ->
      user = factory.Users!
      mod = factory.Modules user_id: user.id
      add_url = "/add-to-manifest/#{user.slug}/#{mod.name}"
      remove_url = "/remove-from-manifest/#{user.slug}/#{mod.name}/#{root.id}"

    it "should load redirect logged out on add", ->
      assert.same 302, (request add_url)

    it "should load redirect logged out on add", ->
      assert.same 302, (request remove_url)

    it "should load add page", ->
      assert.same 200, (request_as user, add_url)

    it "should load add the module", ->
      assert.same 302, (request_as user, add_url, {
        post: {
          manifest_id: root.id
        }
      })

      assert.same 1, #root\find_modules!\get_page!

    it "should load remove page", ->
      ManifestModules\create root, mod
      assert.same 200, (request_as user, remove_url)

    it "should remove module", ->
      ManifestModules\create root, mod
      assert.same 302, (request_as user, remove_url, {
        post: {}
      })

      assert.same 0, #root\find_modules!\get_page!
