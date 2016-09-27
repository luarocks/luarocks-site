import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"
import truncate_tables from require "lapis.spec.db"

db = require "lapis.db"

factory = require "spec.factory"

import
  Users
  Modules
  ApprovedLabels
  from require "models"


describe "applications.labels", ->
  use_test_server!

  before_each ->
    truncate_tables Users, Modules, ApprovedLabels

  it "shows empty label page", ->
    status = request_as nil, "/labels/calzone"
    assert.same 404, status

  it "shows labels page", ->
    mod = factory.Modules!
    mod\set_labels { "calzone" }

    status = request_as nil, "/labels/calzone"
    assert.same 200, status

  describe "edit labels", ->
    local user, mod

    before_each ->
      user = factory.Users!
      mod = factory.Modules user_id: user.id

    it "loads page to add label when there are no approved labels", ->
      status = request_as user, "/label/add/#{user.slug}/#{mod.name}"
      assert.same 200, status

    it "loads page to add label", ->
      ApprovedLabels\create name: "hello"
      ApprovedLabels\create name: "world"

      status = request_as user, "/label/add/#{user.slug}/#{mod.name}"
      assert.same 200, status

    it "doesn't let random user add label", ->
      other_user = factory.Users!

      status = request_as other_user, "/label/add/#{user.slug}/#{mod.name}"
      assert.same 404, status

      status = request_as other_user, "/label/add/#{user.slug}/#{mod.name}", {
        post: {
          label: "hello world"
        }
      }

      assert.same 404, status

    it "adds label", ->
      status = request_as user, "/label/add/#{user.slug}/#{mod.name}", {
        post: {
          label: "hello world"
        }
      }

      assert.same 302, status
      mod\refresh!
      assert.same {"hello-world"}, mod.labels

      -- noop
      status = request_as user, "/label/add/#{user.slug}/#{mod.name}", {
        post: {
          label: "hello world"
        }
      }

      mod\refresh!
      assert.same {"hello-world"}, mod.labels

    it "loads remove label page", ->
      mod\set_labels { "calzone" }
      status = request_as user, "/label/remove/#{user.slug}/#{mod.name}/calzone"
      assert.same 200, status

    it "doens't load page for invalid label", ->
      status = request_as user, "/label/remove/#{user.slug}/#{mod.name}/calzone"
      assert.same 404, status

    it "removes label", ->
      mod\set_labels { "calzone" }
      status = request_as user, "/label/remove/#{user.slug}/#{mod.name}/calzone", {
        post: { }
      }
      assert.same 302, status

      mod\refresh!
      assert.nil mod.labels

    it "doesn't let random user remove label", ->
      other_user = factory.Users!
      mod\set_labels { "calzone" }

      status = request_as other_user, "/label/remove/#{user.slug}/#{mod.name}/calzone"
      assert.same 404, status

      status = request_as other_user, "/label/remove/#{user.slug}/#{mod.name}/calzone", {
        post: {
          label: "hello world"
        }
      }

      assert.same 404, status



