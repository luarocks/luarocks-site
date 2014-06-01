

user_slug, module_name = ...
HELP = "moon cmd/take_module.moon USER_NAME [MODULE_NAME]"
unless user_slug
  print HELP
  os.exit!

import connect_postgres from require "cmd.helpers"
connect_postgres!

import Users, Modules, Manifests, ManifestModules from require "models"

luarocks = Users\find slug: "luarocks"

user = Users\find slug: assert user_slug, "missing user slug"
assert user, "could not find user '#{user_slug}'"

take_module = (module_name) ->
  print "Giving #{module_name} to #{user.username}"

  mod = Modules\find {
      name: assert module_name, "missing module name"
      user_id: luarocks.id
  }

  return nil, "could not find module '#{module_name}'" unless mod

  new_module = mod\copy_to_user user

  root = Manifests\root!
  if mm = ManifestModules\find module_id: mod.id, manifest_id: root.id
    mm\delete!
    assert ManifestModules\create root, new_module

if module_name
  assert take_module module_name
else
  for mod in *user\all_modules!
    take_module mod.name

