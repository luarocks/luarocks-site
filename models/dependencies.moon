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
-- CREATE INDEX dependencies_dependency_name_idx ON dependencies USING btree (dependency_name);
--
class Dependencies extends Model
  @primary_key: {"version_id", "dependency_name"}

  -- Splits a rockspec dependency string into its name and constraint, eg.
  -- "Foo>=1.0" -> "foo", ">=1.0". The name pattern and lowercasing match
  -- LuaRocks 3's queries.from_dep_string, so a space before the operator is
  -- optional and a namespace prefix (ns/foo) is kept as part of the name.
  @parse_dependency: (str) =>
    name, constraint = str\match "^%s*([a-zA-Z0-9%.%-%_]*/?[a-zA-Z0-9][a-zA-Z0-9%.%-%_]*)%s*([^/]*)"
    return nil unless name
    import trim from require "lapis.util"
    constraint = trim constraint
    name\lower!, constraint != "" and constraint or nil

  @preload_modules: (dependencies, manifest) =>
    import Manifests, ManifestModules, Modules, Users from require "models"
    manifest or= Manifests\root!

    ManifestModules\include_in dependencies, "module_name", {
      flip: true
      local_key: "dependency_name"
      where: {
        manifest_id: manifest.id
      }
    }

    Modules\include_in [dep.manifest_module for dep in *dependencies when dep.manifest_module], "module_id"
    Users\include_in [dep.manifest_module.module for dep in *dependencies when dep.manifest_module], "user_id"

    dependencies

  parse_version: =>
    _, constraint = @@parse_dependency @dependency
    constraint

