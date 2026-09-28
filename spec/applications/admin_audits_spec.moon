import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "admin audits", ->
  use_test_server!

  import Users, Modules, Versions, Rocks, FileAudits from require "spec.models"

  local admin, version

  before_each ->
    admin = factory.Users flags: 1
    version = factory.Versions!

  it "renders audits in every status", ->
    FileAudits\audit_version version

    completed = FileAudits\audit_version version
    completed\mark_started "111"
    completed\mark_complete { findings: {} }

    failed = FileAudits\audit_version version
    failed\mark_failed "Analysis result is not a JSON object"

    status, body = request_as admin, "/admin/audits"
    assert.same 200, status
    assert.truthy body\find "status_pending", 1, true
    assert.truthy body\find "status_completed", 1, true
    assert.truthy body\find "status_failed", 1, true
    assert.truthy body\find "Analysis result is not a JSON object", 1, true
    assert.truthy body\find "Run again", 1, true
    assert.truthy body\find "Dispatch", 1, true

  it "forbids non-admins", ->
    status = request_as factory.Users!, "/admin/audits"
    assert.not.same 200, status

  it "runs again by creating a new audit", ->
    first = FileAudits\audit_version version
    first\mark_failed "failed"

    status, body, headers = request_as admin, "/admin/audits/create", {
      post: {
        object_type: "version"
        object_id: tostring version.id
      }
    }

    assert.same 302, status
    assert.truthy headers.location\match "/admin/audits$"

    audits = version\get_audits!
    assert.same 2, #audits
    assert.same FileAudits.statuses.pending, audits[1].status

    first\refresh!
    assert.same FileAudits.statuses.failed, first.status
    assert.same "failed", first.error_message

  it "doesn't dispatch a finished audit", ->
    audit = FileAudits\audit_version version
    audit\mark_started "222"
    audit\mark_complete { ok: true }

    request_as admin, "/admin/audits/#{audit.id}/dispatch", {
      post: {}
    }

    audit\refresh!
    assert.same FileAudits.statuses.completed, audit.status
    assert.same "222", audit.external_id
