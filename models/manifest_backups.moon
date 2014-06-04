
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

class ManifestBackups extends Model
  @timestamp: true

  do_backup: =>
    import Manifests from require "models"
    m = Manifests\find @manifest_id
    -- TODO do for non root
    manifest_url = "http://#{config.host}"
    temp_path = "/tmp/moonrocks_#{m.name}_mirror"

    if @development
      manifest_url ..= "/dev"
      temp_path ..= "_dev"

    git = git_runner temp_path

    exec "mkdir -p #{temp_path}"
    res = git "status &> /dev/null"

    if res > 0
      git "init"
      git "remote add origin '#{@repository_url}'"

    git "fetch"
    git "reset --hard origin/master"

    -- do the backup
    update_manifest_on_disk manifest_url, temp_path

    -- update
    git "add -A ."
    git "commit -m 'updated backup'"
    git "push origin master"
    true
