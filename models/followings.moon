db = require "lapis.db"
import Model, enum from require "lapis.db.model"

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

  @kind: enum {
    subscription: 1
    bookmark: 2
  }

  @relations: {
    {"source_user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"module", "Modules"}
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

    self.kind = opts.kind

    f = safe_insert @, opts
    f\increment(1) if f
    f

  delete: =>
    if super!
      @increment -1
      true

  increment: (amount=1) =>
    amount = assert tonumber amount
    import Users from require "models"

    cls = @@model_for_object_type @object_type

    user_column, module_column = if self.kind == 2
      "stared_count", "stars_count"
    else
      "following_count", "followers_count"

    Users\load(id: @source_user_id)\update {
      [user_column]: db.raw "#{user_column} + #{amount}"
    }, timestamp: false

    cls\load(id: @object_id)\update {
      [module_column]: db.raw "#{module_column} + #{amount}"
    }, timestamp: false
