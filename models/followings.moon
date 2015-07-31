db = require "lapis.db"
import Model from require "lapis.db.model"

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
    }}
  }

  @create: (opts) =>
    opts.object_type = @@object_types\for_db opts.object_type
    Model.create @, opts

