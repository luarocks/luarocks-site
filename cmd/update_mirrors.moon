
import connect_postgres from require "cmd.helpers"
connect_postgres!

import Manifests, ManifestBackups from require "models"


-- How to create backup:

-- root = Manifests\root!
-- ManifestBackups\create {
--   manifest_id: root.id
--   -- repository_url: "git@github.com:rocks-moonscript-org/moonrocks-mirror.git"
--   repository_url: "git@github.com:rocks-moonscript-org/staging-mirror.git"
-- }

for backup in *ManifestBackups\select!
  backup\do_backup!
