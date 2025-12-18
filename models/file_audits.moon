
import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.models"

db = require "lapis.db"
date = require "date"

class FileAudits extends Model
  @timestamp: true

  @statuses: enum {
    pending: 1
    running: 2
    completed: 3
    failed: 4
  }

  @runners: enum {
    github_actions: 1
  }

  @relations: {
    {"object", polymorphic_belongs_to: {
      [1]: {"version", "Versions"}
      [2]: {"rock", "Rocks"}
    }}
  }

  -- Create audit for a rockspec (version)
  @audit_version: (version, runner=@runners.github_actions) =>
    safe_insert @, {
      object_type: @object_types.version
      object_id: version.id
      status: @statuses.pending
      runner: runner
    }, {
      object_type: @object_types.version
      object_id: version.id
    }

  -- Create audit for a rock
  @audit_rock: (rock, runner=@runners.github_actions) =>
    safe_insert @, {
      object_type: @object_types.rock
      object_id: rock.id
      status: @statuses.pending
      runner: runner
    }, {
      object_type: @object_types.rock
      object_id: rock.id
    }

  start_run: (external_id) =>
    @update {
      status: @@statuses.running
      :external_id
      started_at: db.raw "now() at time zone 'utc'"
    }

  mark_complete: (result_data) =>
    import to_json from require "lapis.util"
    @update {
      status: @@statuses.completed
      result_data: if type(result_data) == "table"
        to_json result_data
      else
        result_data
      finished_at: db.raw "now() at time zone 'utc'"
    }

  mark_failed: (error_message) =>
    @update {
      status: @@statuses.failed
      :error_message
      finished_at: db.raw "now() at time zone 'utc'"
    }

  duration: =>
    return nil unless @started_at and @finished_at
    delta = date.diff date(@finished_at), date(@started_at)
    delta\spanseconds!

  -- Get the download URL for the file being audited
  get_file_url: =>
    @get_object!\url!

  get_file_key: =>
    obj = @get_object!
    switch @object_type
      when @@object_types.version
        obj.rockspec_key
      when @@object_types.rock
        obj.rock_key

  get_file_type: =>
    switch @object_type
      when @@object_types.version
        "rockspec"
      when @@object_types.rock
        "rock"

  -- Returns the payload to send as inputs to the GitHub Action
  get_dispatch_payload: =>
    config = require("lapis.config").get!

    file_type = @get_file_type!
    return nil, "unknown object type" unless file_type

    {
      audit_id: tostring @id
      file_url: @get_file_url!
      file_type: file_type
      callback_url: config.audit_callback_url
    }

