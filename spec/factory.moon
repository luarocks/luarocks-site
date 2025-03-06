
models = require "models"
db = require "lapis.db"
import Model from require "lapis.db.model"

next_counter = do
  counters = setmetatable {}, __index: => 1
  (name) ->
    with counters[name]
      counters[name] += 1

next_email = ->
  "me-#{next_counter "email"}@example.com"

local *

Users = (opts={}) ->
  opts.username or= "user-#{next_counter "username"}"
  opts.email or= next_email!
  opts.password or= "my-password"

  user = assert models.Users\create opts.username, opts.password, opts.email
  opts.password = nil
  opts.username = nil
  opts.email = nil

  if next opts
    user\update opts

  user

Modules = (opts={}) ->
  opts.name or= "module_#{next_counter "module"}"
  opts.user_id or= Users!.id
  opts.current_version_id or= -1
  opts.summary or= "This is my test module #{opts.name}"

  assert Model.create models.Modules, opts

Versions = (opts={}) ->
  module_name = "some_module"

  if opts.module_id
    mod = models.Modules\find opts.module_id
    module_name = mod.name
  else
    mod = Modules!
    module_name = mod.name
    opts.module_id = mod.id

  opts.version_name or= if opts.development
    "scm-#{next_counter "version"}"
  else
    "0.0.0-#{next_counter "version"}"

  opts.rockspec_fname = "#{module_name}-#{opts.version_name}.rockspec"
  opts.rockspec_key = "/spec/#{opts.rockspec_fname}"

  assert Model.create models.Versions, opts

Rocks = (opts={}) ->
  opts.version_id or= Versions!.id
  opts.arch or= "arch_#{next_counter "arch"}"

  opts.rock_fname = "some_module-#{opts.arch}.rock"
  opts.rock_key = "/spec/#{opts.rock_fname}"

  assert Model.create models.Rocks, opts

Manifests = (opts={}) ->
  opts.description or= "Manifest description #{next_counter "manifest-desc"}"
  opts.name or= "manifest-#{next_counter "manifest-slug"}"

  if opts.is_open == nil
    opts.is_open = true

  assert Model.create models.Manifests, opts

ManifestModules = (opts={}) ->
  unless opts.module_id
    mod = Modules!
    opts.module_id = mod.id
    opts.module_name = mod.name

  unless opts.module_name
    opts.module_name = models.Modules\find(opts.module_id).name

  opts.manifest_id or= Manifests!

  assert Model.create models.ManifestModules, opts

ApiKeys = (opts={}) ->
  opts.user_id or= Users!.id
  models.ApiKeys\generate opts.user_id, "specs"

Followings = (opts={}) ->
  opts.object or= Modules!
  opts.source_user_id or= Users!.id
  models.Followings\create opts

ManifestAdmins = (opts={}) ->
  opts.manifest_id or= Manifests!.id
  opts.user_id or= Users!.id

  if opts.is_owner == nil
    opts.is_owner = true

  assert Model.create models.ManifestAdmins, opts

{ :next_counter, :next_email, :Users, :Modules, :Versions, :Rocks, :Manifests,
  :ManifestModules, :ApiKeys, :Followings, :ManifestAdmins }
