
db = require "lapis.db"
bucket = require "storage_bucket"

import Model from require "lapis.db.model"
import increment_counter, safe_insert from require "helpers.models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE rocks (
--   id integer NOT NULL,
--   version_id integer NOT NULL,
--   arch character varying(255) NOT NULL,
--   downloads integer DEFAULT 0 NOT NULL,
--   rock_key character varying(255) NOT NULL,
--   rock_fname character varying(255) NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   revision integer DEFAULT 1 NOT NULL
-- );
-- ALTER TABLE ONLY rocks
--   ADD CONSTRAINT rocks_pkey PRIMARY KEY (id);
-- CREATE INDEX rocks_rock_fname_idx ON rocks USING btree (rock_fname);
-- CREATE UNIQUE INDEX rocks_rock_key_idx ON rocks USING btree (rock_key);
-- CREATE UNIQUE INDEX rocks_version_id_arch_idx ON rocks USING btree (version_id, arch);
--
class Rocks extends Model
  @timestamp: true

  @relations: {
    {"version", belongs_to: "Versions"}
  }

  @create: (version, arch, rock_key) =>
    safe_insert @, {
      version_id: version.id
      rock_fname: rock_key\match "/([^/]*)$"
      :arch, :rock_key
    }, {version_id: version.id, :arch }

  url: => bucket\file_url @rock_key .. "?#{@revision}"

  url_key: => @arch

  url_params: =>
    version = @get_version!
    mod = version\get_module!
    user = mod\get_user!

    nil, "/manifests/#{user\url_key!}/#{@rock_fname}"

  increment_download: =>
    import Versions from require "models"

    increment_counter @, "downloads"
    version = @version or Versions\find id: @version_id
    version\increment_download {"downloads"}

  delete: =>
    if super!
      bucket\delete_file @rock_key
      true

  increment_revision: =>
    @update revision: db.raw "revision + 1"

  allowed_to_edit: (user) =>
    return false unless user
    @get_version!\allowed_to_edit user


