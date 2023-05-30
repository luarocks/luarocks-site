import Manifests, ManifestBackups from require "models"

switch ...
  when "list"
    backups = ManifestBackups\select!
    Manifests\include_in backups, "manifest_id"
    print "Configured backups:"
    print "none! (add with `add`)" unless next backups

    for backup in *backups
      print "[#{backup.id}] #{backup.manifest.name} -> #{backup.repository_url} (dev: #{backup.development})"

  when "remove"
    _, backup_id = ...
    backup = ManifestBackups\find assert backup_id, "missing backup id"
    assert backup, "could not find backup with id #{backup_id}"
    backup\delete!

  when "add"
    _, name, git, dev = ...
    assert name, "missing manifest name"
    assert git, "missing git repo url"

    m = assert Manifests\find(:name), "could not find manifest"
    ManifestBackups\create {
      manifest_id: m.id
      repository_url: git
      development: not not dev
    }
  else
    for backup in *ManifestBackups\select!
      backup\do_backup!

