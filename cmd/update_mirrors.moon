
argparse = require "argparse"

parser = argparse "update_mirrors.moon", "Manage manifest backups"

parser\add_help_command!
parser\command_target "command"

parser\command "list", "List all configured backups"

with parser\command "remove", "Remove a backup"
  \argument("backup_id", "ID of the backup to be removed")\convert tonumber
  \flag("--confirm", "Confirm removal of backup")

with parser\command "add", "Add a new backup"
  \argument("name", "Manifest name")
  \argument("git", "Git repository URL")
  \flag("--dev", "Flag backup as development")

args = parser\parse [v for _, v in ipairs _G.arg]

import Manifests, ManifestBackups from require "models"
import preload from require "lapis.db.model"

switch args.command
  when "list"
    backups = ManifestBackups\select!
    preload backups, "manifest"
    print "Configured backups:"
    print "none! (add with `add`)" unless next backups

    for backup in *backups
      manifest = backup\get_manifest!
      print "[#{backup.id}] #{manifest.name} -> #{backup.repository_url} (dev: #{backup.development})"

  when "remove"
    backup = ManifestBackups\find args.backup_id
    assert backup, "could not find backup with id #{args.backup_id}"

    if args.confirm
      print backup\delete!
    else
      print "Will remove backup: #{backup.id}?"
      require("moon").p backup
      print "Pass --confirm to delete it"

  when "add"
    m = assert Manifests\find(name: args.name), "could not find manifest with name '#{args.name}'"

    backup = ManifestBackups\create {
      manifest_id: m.id
      repository_url: args.git
      development: args.dev
    }
    if backup
      print "Added backup: #{backup.id}"
  else
    for backup in *ManifestBackups\select!
      backup\do_backup!

