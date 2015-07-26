db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE dependencies (
--   version_id integer NOT NULL,
--   dependency_name character varying(255) NOT NULL,
--   dependency character varying(255) NOT NULL
-- );
-- ALTER TABLE ONLY dependencies
--   ADD CONSTRAINT dependencies_pkey PRIMARY KEY (version_id, dependency_name);
--
class Dependencies extends Model
  @primary_key: {"version_id", "dependency_name"}
