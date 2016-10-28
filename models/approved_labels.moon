
import Model from require "lapis.db.model"
import slugify from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE approved_labels (
--   id integer NOT NULL,
--   name character varying(255) NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY approved_labels
--   ADD CONSTRAINT approved_labels_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX approved_labels_name_idx ON approved_labels USING btree (name);
--
class ApprovedLabels extends Model
  @timestamp: true

  @create: (opts) =>
    opts.name = slugify opts.name
    assert opts.name != ""
    super opts

  url_params: (req, ...) =>
    "label", { label: @name }, ...
