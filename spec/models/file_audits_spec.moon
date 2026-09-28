factory = require "spec.factory"

describe "models.file_audits", ->
  import
    Users
    Modules
    Versions
    Rocks
    FileAudits
    from require "spec.models"

  it "creates repeated audits for the same object", ->
    version = factory.Versions!
    rock = factory.Rocks version_id: version.id

    first = FileAudits\audit_version version
    second = FileAudits\audit_version version
    rock_audit = FileAudits\audit_rock rock

    assert.truthy first
    assert.truthy second
    assert.not.same first.id, second.id
    assert.same FileAudits.statuses.pending, second.status

    assert.same {second.id, first.id}, [a.id for a in *version\get_audits!]
    assert.same {rock_audit.id}, [a.id for a in *rock\get_audits!]

    audits = version\get_module!\get_audits!
    assert.same {rock_audit.id, second.id, first.id}, [a.id for a in *audits]

  it "only dispatches pending audits", ->
    version = factory.Versions!
    audit = FileAudits\audit_version version

    assert.truthy audit\mark_dispatched!
    assert.same FileAudits.statuses.dispatched, audit.status

    -- already dispatched
    assert.falsy audit\mark_dispatched!

  it "doesn't redispatch finished audits", ->
    version = factory.Versions!

    completed = FileAudits\audit_version version
    completed\mark_started "123"
    completed\mark_complete { findings: {} }

    failed = FileAudits\audit_version version
    failed\mark_failed "analysis failed"

    assert.falsy completed\mark_dispatched!
    assert.falsy failed\mark_dispatched!

    completed\refresh!
    assert.same FileAudits.statuses.completed, completed.status
    assert.same "123", completed.external_id
    assert.same { findings: {} }, completed.result_data

    failed\refresh!
    assert.same FileAudits.statuses.failed, failed.status
    assert.same "analysis failed", failed.error_message
