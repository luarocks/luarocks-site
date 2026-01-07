
import Model, enum from require "lapis.db.model"
import insert_on_conflict_ignore from require "helpers.models"

db = require "lapis.db"
date = require "date"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE file_audits (
--   id integer NOT NULL,
--   object_type smallint NOT NULL,
--   object_id integer NOT NULL,
--   status smallint DEFAULT 1 NOT NULL,
--   runner smallint DEFAULT 1 NOT NULL,
--   external_id text,
--   result_data json,
--   error_message text,
--   started_at timestamp without time zone,
--   finished_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY file_audits
--   ADD CONSTRAINT file_audits_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX file_audits_object_type_object_id_idx ON file_audits USING btree (object_type, object_id);
-- CREATE INDEX file_audits_status_idx ON file_audits USING btree (status);
--
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
    insert_on_conflict_ignore @, {
      object_type: @object_types.version
      object_id: version.id
      status: @statuses.pending
      runner: runner
    }

  -- Create audit for a rock
  @audit_rock: (rock, runner=@runners.github_actions) =>
    insert_on_conflict_ignore @, {
      object_type: @object_types.rock
      object_id: rock.id
      status: @statuses.pending
      runner: runner
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

