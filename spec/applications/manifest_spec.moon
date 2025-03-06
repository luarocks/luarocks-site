import use_test_server from require "lapis.spec"
import request, request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.manifest", ->
  use_test_server!

  import Manifests, ManifestAdmins, Users from require "spec.models"

  describe "edit manifest", ->
    local user, manifest, manifest_admin

    before_each ->
      user = factory.Users!
      manifest = factory.Manifests {
        name: "test-manifest"
        display_name: "Test Manifest"
        description: "Original description"
      }

      manifest_admin = factory.ManifestAdmins {
        manifest_id: manifest.id
        user_id: user.id
        is_owner: true
      }

    it "redirects when not logged in", ->
      status = request "/m/test-manifest/edit"
      assert.same 302, status

    it "404s for non-existent manifest", ->
      status = request_as user, "/m/nonexistent-manifest/edit"
      assert.same 404, status

    it "forbids editing when not an admin or owner", ->
      non_admin = factory.Users!
      status, body = request_as non_admin, "/m/test-manifest/edit"
      assert.same 404, status

    it "allows manifest admin to access edit page", ->
      status = request_as user, "/m/test-manifest/edit"
      assert.same 200, status

    it "allows site admin to access edit page", ->
      admin_user = factory.Users!
      admin_user\update flags: Users.flags.admin
      status = request_as admin_user, "/m/test-manifest/edit"
      assert.same 200, status

    it "updates manifest name and description", ->
      status, body, headers = request_as user, "/m/test-manifest/edit", {
        post: {
          display_name: "New Display Name"
          description: "New description text"
        }
      }

      assert.same 302, status
      
      -- Verify redirect to manifest page
      assert.truthy headers.location\match("/m/test%-manifest$")
      
      -- Reload manifest to check changes
      manifest\refresh!
      assert.same "New Display Name", manifest.display_name
      assert.same "New description text", manifest.description

    it "can clear display name and description", ->
      status, body, headers = request_as user, "/m/test-manifest/edit", {
        post: {
          display_name: ""
          description: ""
        }
      }

      assert.same 302, status
      
      -- Reload manifest to check changes
      manifest\refresh!
      assert.same nil, manifest.display_name
      assert.same nil, manifest.description
