
db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE manifest_admins (
--   user_id integer NOT NULL,
--   manifest_id integer NOT NULL,
--   is_owner boolean NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY manifest_admins
--   ADD CONSTRAINT manifest_admins_pkey PRIMARY KEY (user_id, manifest_id);
-- ALTER TABLE ONLY manifest_admins
--   ADD CONSTRAINT manifest_admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
--
class ManifestAdmins extends Model
  @timestamp: true
  @primary_key: {"user_id", "manifest_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"manifest", belongs_to: "Manifests"}
  }

  @create: (manifest, user, is_owner=false) =>
    super {
      manifest_id: manifest.id
      user_id: user.id
      :is_owner
    }

  @remove: (manifest, user) =>
    assert user.id and manifest.id, "Missing user/manifest"
    db.delete @@table_name!, {
      manifest_id: manifest.id
      user_id: user.id
    }
