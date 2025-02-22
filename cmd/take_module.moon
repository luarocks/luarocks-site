
argparse = require "argparse"

parser = argparse("take_module.moon", "Transfer module ownership from the `luarocks` user to another user")

parser\argument("user_slug", "user slug that will recieve the module")
parser\argument("module_name", "name of the module to be transferred. Will try every module name owned by target user if not provided")\args "?"

parser\option("--source_user", "User slug we are taking from", "luarocks")

args = parser\parse [v for _, v in ipairs _G.arg]

import Users, Modules, Manifests, ManifestModules from require "models"
db = require "lapis.db"

luarocks = assert Users\find(slug: args.source_user), "failed to find source user '#{args.source_user}'"
user = assert Users\find(slug: args.user_slug), "failed to find destination user '#{args.user_slug}'"

take_module = (module_name) ->
  io.stdout\write "Giving #{module_name} to #{user\name_for_display!}..."
  io.stdout\flush!

  mod = Modules\find {
    name: assert module_name, "missing module name"
    user_id: luarocks.id
  }

  unless mod
    print "Failed: could not find module '#{module_name}'"
    return nil, "failed"

  mod\copy_to_user user, true
  print "Success"
  true

if args.module_name
  assert take_module args.module_name
else
  for mod in *user\get_modules!
    take_module mod.name
