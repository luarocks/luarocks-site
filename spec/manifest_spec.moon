import use_test_server from require "lapis.spec"
import request, request_as, should_load from require "spec.helpers"

factory = require "spec.factory"

parse_manifest = (text) ->
  fn = assert loadstring text
  m = {}
  setfenv fn, m
  assert pcall(fn)
  m

shell_escape = (str) ->
  str\gsub "'", "''"

-- /m/root/... redirects to the top level root manifest paths
follow_request = (url, opts) ->
  status, body, headers = request url, opts
  if status == 301
    path = headers.location\gsub "^%a+://[^/]+", ""
    return request path, opts

  status, body, headers

request_manifest = (url) ->
  status, body = follow_request url
  assert.same 200, status
  parse_manifest body

should_load_manifest = (url, fn) ->
  it "should load manifest #{url}", ->
    m = request_manifest url
    fn m if fn

should_load_json_manifest = (url, fn) ->
  it "should load json manifest #{url}", ->
    status, body = follow_request url
    assert.same 200, status
    res = require("cjson").decode body
    fn res if fn

should_load_zip_manifest = (url, fn) ->
  it "should zip load manifest #{url}", ->
    status, body = follow_request url
    assert.same 200, status
    assert body\match("^PK"), "not valid zip"

    import encode_base64 from require "lapis.util.encoding"
    f = io.popen "echo '#{shell_escape encode_base64 body}' | base64 -d | funzip", "r"
    unzipped = f\read "*a"
    m = parse_manifest unzipped
    fn m if fn

prefixes = {"", "/m/root"}

describe "moonrocks", ->
  use_test_server!

  local root

  import Manifests, ManifestModules, Users,
    Modules, Rocks, Versions from require "spec.models"

  before_each ->
    root = Manifests\create "root", true

  is_empty_manifest = (m) ->
    assert.same {
      repository: {}
      commands: {}
      modules: {}
    }, m

  for prefix in *prefixes
    describe "prefix(#{prefix})", ->
      -- doesn't load invalid pages
      should_load "#{prefix}/manifestfwafe", 404
      should_load "#{prefix}/manifest/nope", 404
      should_load "#{prefix}/manifest-4.0", 404
      should_load "#{prefix}/manifest.wow", 404
      should_load "#{prefix}/manifest-5.2.wow", 404

      should_load "#{prefix}/dev/manifests", 404
      should_load "#{prefix}/dev/manifestfwafe", 404
      should_load "#{prefix}/dev/manifest/nope", 404
      should_load "#{prefix}/dev/manifest-4.0", 404
      should_load "#{prefix}/dev/manifest.wow", 404
      should_load "#{prefix}/dev/manifest-5.2.wow", 404

      for v in *{"", "-5.1", "-5.2", "-5.3", "-5.4", "-5.5"}
        should_load_manifest "#{prefix}/manifest#{v}", is_empty_manifest
        should_load_manifest "#{prefix}/dev/manifest#{v}", is_empty_manifest

        should_load_zip_manifest "#{prefix}/manifest#{v}.zip"
        should_load_zip_manifest "#{prefix}/dev/manifest#{v}.zip"

        should_load_json_manifest "#{prefix}/manifest#{v}.json"
        should_load_json_manifest "#{prefix}/dev/manifest#{v}.json"

  describe "root custom manifest", ->
    for {url, target} in *{
      {"/m/root/manifest", "/manifest"}
      {"/m/root/manifest-5.1", "/manifest-5.1"}
      {"/m/root/manifest-5.4.json", "/manifest-5.4.json"}
      {"/m/root/manifest.zip", "/manifest.zip"}
      {"/m/root/dev/manifest", "/dev/manifest"}
      {"/m/root/dev/manifest-5.3.zip", "/dev/manifest-5.3.zip"}
    }
      it "should redirect #{url} to #{target}", ->
        status, _, headers = request url
        assert.same 301, status
        assert.truthy headers.location\match "^%a+://[^/]+#{target\gsub "%p", "%%%0"}$"

  has_module = (manifest, mod) ->
    assert manifest.repository[mod.name],
      "manifest should have module"

  describe "with a module", ->
    local mod

    before_each ->
      mod = factory.Modules!
      ManifestModules\create root, mod

    for prefix in *prefixes
      describe "prefix(#{prefix})", ->
        should_load_manifest "#{prefix}/manifest", is_empty_manifest

        describe "with regular version", ->
          local version

          before_each ->
            version = factory.Versions module_id: mod.id

          -- no lua version, should have module in versioned
          should_load_manifest "#{prefix}/manifest", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/manifest-5.1", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/manifest-5.2", (m) -> has_module m, mod

          should_load_zip_manifest "#{prefix}/manifest.zip", (m) -> has_module m, mod
          should_load_zip_manifest "#{prefix}/manifest-5.1.zip", (m) -> has_module m, mod
          should_load_zip_manifest "#{prefix}/manifest-5.2.zip", (m) -> has_module m, mod

          should_load_manifest "#{prefix}/dev/manifest", is_empty_manifest

          should_load_json_manifest "#{prefix}/dev/manifest-5.1.json", (res) ->
            assert.same {
              modules: {}
              commands: {}
              repository: {}
            }, res

          should_load_json_manifest "#{prefix}/manifest-5.1.json", (res) ->
            mod = version\get_module!
            assert.same {
              modules: {}
              commands: {}
              repository: {
                [mod.name]: {
                  [version.version_name]: {
                    {arch: "rockspec"}
                  }
                }
              }
            }, res

          it "should do HEAD", ->
            status, body, headers = follow_request "#{prefix}/manifest", {
              method: "HEAD"
            }

            assert.same 200, status
            assert.same "", body
            assert.truthy headers["Last-Modified"]

    describe "with archived version #ddd", ->
      before_each ->
        v_one = factory.Versions module_id: mod.id, version_name: "1.1.1", archived: true
        v_two = factory.Versions module_id: mod.id, version_name: "1.1.2"

      for prefix in *prefixes
        describe "prefix(#{prefix})", ->
          should_load_manifest "#{prefix}/manifest", (m) ->
            module_name = next m.repository
            versions = [k for k in pairs m.repository[module_name]]
            assert.same {"1.1.2"}, versions

    describe "with development version", ->
      local version

      before_each ->
        version = factory.Versions module_id: mod.id, development: true

      for prefix in *prefixes
        describe "prefix(#{prefix})", ->
          should_load_manifest "#{prefix}/manifest", is_empty_manifest
          should_load_manifest "#{prefix}/dev/manifest", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/dev/manifest-5.1", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/dev/manifest-5.2", (m) -> has_module m, mod

          should_load_zip_manifest "#{prefix}/dev/manifest.zip", (m) -> has_module m, mod
          should_load_zip_manifest "#{prefix}/dev/manifest-5.1.zip", (m) -> has_module m, mod
          should_load_zip_manifest "#{prefix}/dev/manifest-5.2.zip", (m) -> has_module m, mod

          should_load_json_manifest "#{prefix}/manifest-5.1.json", (res) ->
            assert.same {
              modules: {}
              commands: {}
              repository: {}
            }, res

          should_load_json_manifest "#{prefix}/dev/manifest-5.1.json", (res) ->
            mod = version\get_module!
            assert.same {
              modules: {}
              commands: {}
              repository: {
                [mod.name]: {
                  [version.version_name]: {
                    {arch: "rockspec"}
                  }
                }
              }
            }, res

    describe "with versioned version", ->
      local version

      before_each ->
        version = factory.Versions module_id: mod.id, lua_version: "lua >= 5.1, < 5.2"

      -- no lua version, should have module in versioned
      for prefix in *prefixes
        describe "prefix(#{prefix})", ->
          should_load_manifest "#{prefix}/manifest", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/manifest-5.1", (m) -> has_module m, mod
          should_load_manifest "#{prefix}/manifest-5.2", is_empty_manifest

          should_load_manifest "#{prefix}/dev/manifest", is_empty_manifest


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

      for prefix in *prefixes
        describe "prefix(#{prefix})", ->
          should_load_manifest "#{prefix}/manifest", (m) ->
            assert.same {
              [mod.name]: {
                ["1-1"]: { { arch: "rockspec" }, { arch: "win99" } }
                ["2-1"]: { { arch: "rockspec" } }
              }
            }, m.repository

          should_load_manifest "#{prefix}/manifest-5.1", (m) ->
            assert.same {
              [mod.name]: {
                ["1-1"]: { { arch: "rockspec" }, { arch: "win99" } }
                ["2-1"]: { { arch: "rockspec" } }
              }
            }, m.repository

          should_load_manifest "#{prefix}/manifest-5.2", (m) ->
            assert.same {
              [mod.name]: {
                ["2-1"]: { { arch: "rockspec" } }
              }
            }, m.repository


          should_load_manifest "#{prefix}/dev/manifest", (m) ->
            assert.same {
              [mod.name]: {
                ["git-1"]: { { arch: "rockspec" } }
              }
            }, m.repository

          should_load_manifest "#{prefix}/dev/manifest-5.1", (m) ->
            assert.same {
              [mod.name]: {
                ["git-1"]: { { arch: "rockspec" } }
              }
            }, m.repository

          should_load_json_manifest "#{prefix}/dev/manifest-5.1.json"

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

    should_load "/manifests/tester/manifests", 404
    should_load "/manifests/tester/manifestfwafe", 404
    should_load "/manifests/tester/manifest/nope", 404
    should_load "/manifests/tester/manifest-4.0", 404
    should_load "/manifests/tester/manifest.wow", 404
    should_load "/manifests/tester/manifest-5.2.wow", 404

    should_load_manifest "/manifests/tester/manifest", is_empty_manifest
    should_load_manifest "/manifests/tester/manifest-5.1", is_empty_manifest
    should_load_manifest "/manifests/tester/manifest-5.2", is_empty_manifest
    should_load_json_manifest "/manifests/tester/manifest-5.2.json"

    describe "with regular version", ->
      local mod, version

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id


      should_load_manifest "/manifests/tester/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.2", (m) -> has_module m, mod
      should_load_json_manifest "/manifests/tester/manifest-5.2.json"

    -- development versions show up by default in user manifest at the moment
    describe "with development version", ->
      local mod, version

      before_each ->
        mod = factory.Modules user_id: user.id
        version = factory.Versions module_id: mod.id, development: true

      should_load_manifest "/manifests/tester/manifest", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/manifests/tester/manifest-5.2", (m) -> has_module m, mod
      should_load_json_manifest "/manifests/tester/manifest-5.2.json"

  describe "custom manifest", ->
    local manifest

    before_each ->
      manifest = Manifests\create "custom", true

    should_load "/m/custom/manifests", 404
    should_load "/m/custom/manifest-4.0", 404
    should_load "/m/custom/manifest.wow", 404
    should_load "/m/custom/dev/manifest-4.0", 404
    should_load "/m/nonexistent/manifest", 404

    should_load_manifest "/m/custom/manifest", is_empty_manifest
    should_load_manifest "/m/custom/dev/manifest", is_empty_manifest
    should_load_zip_manifest "/m/custom/manifest-5.1.zip", is_empty_manifest
    should_load_json_manifest "/m/custom/manifest-5.1.json", is_empty_manifest

    describe "with regular version", ->
      local mod, version

      before_each ->
        mod = factory.Modules!
        version = factory.Versions module_id: mod.id
        ManifestModules\create manifest, mod

      should_load_manifest "/m/custom/manifest", (m) -> has_module m, mod
      should_load_manifest "/m/custom/manifest-5.1", (m) -> has_module m, mod
      should_load_manifest "/m/custom/dev/manifest", is_empty_manifest
      should_load_zip_manifest "/m/custom/manifest-5.1.zip", (m) -> has_module m, mod

      should_load_json_manifest "/m/custom/manifest-5.1.json", (res) ->
        assert.same {
          modules: {}
          commands: {}
          repository: {
            [mod.name]: {
              [version.version_name]: {
                {arch: "rockspec"}
              }
            }
          }
        }, res

      it "should not include modules outside the manifest", ->
        other = factory.Modules!
        factory.Versions module_id: other.id

        m = request_manifest "/m/custom/manifest"
        has_module m, mod
        assert.nil m.repository[other.name]

    describe "with development version", ->
      local mod

      before_each ->
        mod = factory.Modules!
        factory.Versions module_id: mod.id, development: true
        ManifestModules\create manifest, mod

      should_load_manifest "/m/custom/manifest", is_empty_manifest
      should_load_manifest "/m/custom/dev/manifest", (m) -> has_module m, mod
      should_load_manifest "/m/custom/dev/manifest-5.1", (m) -> has_module m, mod
      should_load_zip_manifest "/m/custom/dev/manifest-5.1.zip", (m) -> has_module m, mod
      should_load_json_manifest "/m/custom/dev/manifest-5.1.json", (res) ->
        assert.truthy res.repository[mod.name]

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
