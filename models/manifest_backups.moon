
import Model from require "lapis.db.model"
import update_manifest_on_disk from require "helpers.mirror"

colors = require "ansicolors"
config = require("lapis.config").get!

exec = (cmd) ->
  print colors("%{blue}>>%{reset} #{cmd}")
  os.execute cmd

git_runner = (path) ->
  (cmd) ->
    exec "cd #{path} && git #{cmd}"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE manifest_backups (
--   id integer NOT NULL,
--   manifest_id integer NOT NULL,
--   development boolean DEFAULT false,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   last_backup timestamp without time zone,
--   repository_url text NOT NULL
-- );
-- ALTER TABLE ONLY manifest_backups
--   ADD CONSTRAINT manifest_backups_pkey PRIMARY KEY (id);
--
class ManifestBackups extends Model
  @timestamp: true

  @relations: {
    {"manifest", belongs_to: "Manifests"}
  }

  do_backup: (base_dir="/tmp")=>
    import Manifests from require "models"
    m = Manifests\find @manifest_id
    -- TODO do for non root
    manifest_url = "http://#{config.host}"
    temp_path = "#{base_dir}/moonrocks_#{m.name}_mirror"

    if @development
      manifest_url ..= "/dev"
      temp_path ..= "_dev"

    git = git_runner temp_path

    exec "mkdir -p #{temp_path}"
    res = git "status"

    if res > 0
      git "init"
      git "remote add origin '#{@repository_url}'"

    git "fetch"
    git "reset --hard origin/master"

    commit = ->
      git "add -A ."
      git "commit -m 'updated backup'"
      git "push origin master"

    count = 0
    update_manifest_on_disk manifest_url, temp_path, nil, ->
      count += 1
      if count > 500
        commit!
        count = 0

    commit!
    true
