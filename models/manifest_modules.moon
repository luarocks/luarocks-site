
db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE manifest_modules (
--   manifest_id integer NOT NULL,
--   module_id integer NOT NULL,
--   module_name character varying(255) NOT NULL
-- );
-- ALTER TABLE ONLY manifest_modules
--   ADD CONSTRAINT manifest_modules_pkey PRIMARY KEY (manifest_id, module_id);
-- CREATE UNIQUE INDEX manifest_modules_manifest_id_module_name_idx ON manifest_modules USING btree (manifest_id, module_name);
-- CREATE INDEX manifest_modules_module_id_idx ON manifest_modules USING btree (module_id);
--
class ManifestModules extends Model
  @primary_key: {"manifest_id", "module_id"}

  @relations: {
    {"manifest", belongs_to: "Manifests"}
    {"module", belongs_to: "Modules"}
  }

  @create: (manifest, mod) =>
    if @check_unique_constraint manifest_id: manifest.id, module_name: mod.name
      return nil, "Manifest already has a module named `#{mod.name}`"

    res = Model.create @, {
      manifest_id: manifest.id
      module_id: mod.id
      module_name: mod.name
    }
    manifest\purge!
    res

  @remove: (manifest, mod) =>
    assert mod.id and manifest.id, "Missing module/manifest"

    res = db.delete @@table_name!, {
      manifest_id: manifest.id
      module_id: mod.id
    }
    manifest\purge!
    res

  delete: =>
    import Manifests, Modules from require "models"
    @@remove Manifests\find(@manifest_id), Modules\find(@module_id)
