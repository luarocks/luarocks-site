import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

db = require "lapis.db"

factory = require "spec.factory"

describe "applications.labels", ->
  use_test_server!

  import
    Users
    Modules
    ApprovedLabels
    Manifests
    ManifestModules
    from require "spec.models"

  it "shows empty label page", ->
    status = request_as nil, "/labels/calzone"
    assert.same 404, status

  it "shows labels page", ->
    mod = factory.Modules!
    mod\set_labels { "calzone" }

    mod2 = factory.Modules!
    mod2\set_labels { "calzone" }
    ManifestModules\create Manifests\root!, mod2

    status = request_as nil, "/labels/calzone"
    assert.same 200, status

    status = request_as nil, "/labels/calzone?non_root=on"
    assert.same 200, status




