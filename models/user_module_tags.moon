
import slugify from require "lapis.util"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_module_tags (
--   user_id integer NOT NULL,
--   module_id integer NOT NULL,
--   tag character varying(255) NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY user_module_tags
--   ADD CONSTRAINT user_module_tags_pkey PRIMARY KEY (user_id, module_id, tag);
-- CREATE INDEX user_module_tags_module_id_idx ON user_module_tags USING btree (module_id);
--
class UserModuleTags extends Model
  @primary_key: {"user_id", "module_id", "tag"}
  @timestamp: true

  create: (t) =>
    assert t.user_id, "need user id"
    assert t.module_id, "need module id"
    t.tag = slugify assert t.tag, "need tag"
    Model.create @, t

