

user_slug, module_name = ...
HELP = "moon cmd/take_module.moon USER_NAME MODULE_NAME"

import connect_postgres from require "cmd.helpers"
connect_postgres!

import Users, Modules, Manifests, ManifestModules from require "models"

luarocks = Users\find slug: "luarocks"

user = Users\find slug: assert user_slug, "missing user slug (#{HELP})"
mod = Modules\find {
    name: assert module_name, "missing module name (#{HELP})"
    user_id: luarocks.id
}

assert user, "could not find user '#{user_slug}'"
assert mod, "could not find module '#{module_name}'"

new_module = mod\copy_to_user user

root = Manifests\root!
if mm = ManifestModules\find module_id: mod.id, manifest_id: root.id
    mm\delete!
    assert ManifestModules\create root, new_module

