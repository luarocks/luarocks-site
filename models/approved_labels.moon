
db = require "lapis.db"
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

  @find_uncreated: =>
    import Modules from require "models"
    db.query "
      select * from (
        select unnest(labels) as label, count(*) from #{db.escape_identifier Modules\table_name!} group by label order by count(*)
      ) foo
      where not exists(select 1 from approved_labels where name = label)
      order by count desc;
    "

  url_params: (req, ...) =>
    "label", { label: @name }, ...
