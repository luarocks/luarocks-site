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
    @dependency\match("[^%s]+%s*(.*)$")

