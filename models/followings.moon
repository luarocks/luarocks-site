db = require "lapis.db"
import Model from require "lapis.db.model"

import safe_insert from require "helpers.models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE followings (
--   source_user_id integer NOT NULL,
--   object_type smallint NOT NULL,
--   object_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY followings
--   ADD CONSTRAINT followings_pkey PRIMARY KEY (source_user_id, object_type, object_id);
-- CREATE INDEX followings_object_type_object_id_idx ON followings USING btree (object_type, object_id);
--
class Followings extends Model
  @primary_key: {"source_user_id", "object_type", "object_id"}
  @timestamp: true

  @relations: {
    {"source_user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
      [2]: {"user", "Users"}
    }}
  }

  @create: (opts={}) =>
    assert opts.source_user_id, "missing source user id"

    if object = opts.object
      opts.object = nil
      opts.object_id = object.id
      opts.object_type = @object_type_for_object object
    else
      assert opts.object_id, "missing object id"
      opts.object_type = @object_types\for_db opts.object_type

    f = safe_insert @, opts
    f\increment(1, opts.is_starring) if f
    f

  delete: (is_starring) =>
    if super!
      @increment -1, is_starring
      true

  increment: (amount=1, is_starring) =>
    amount = assert tonumber amount
    import Users from require "models"

    cls = @@model_for_object_type @object_type

    if is_starring
      Users\load(id: @source_user_id)\update {
        starrings_count: db.raw "starrings_count + #{amount}"
      }, timestamp: false

      cls\load(id: @object_id)\update {
        starrers_count: db.raw "starrers_count + #{amount}"
      }, timestamp: false
    else
      Users\load(id: @source_user_id)\update {
        following_count: db.raw "following_count + #{amount}"
      }, timestamp: false

      cls\load(id: @object_id)\update {
        followers_count: db.raw "followers_count + #{amount}"
      }, timestamp: false
