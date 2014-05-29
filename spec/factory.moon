
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

  assert models.Users\create opts.username, opts.password, opts.email

Modules = (opts={}) ->
  opts.name or= "module_#{next_counter "module"}"
  opts.user_id or= Users!.id
  opts.current_version_id or= -1
  opts.summary or= "This is my test module #{opts.name}"

  assert Model.create models.Modules, opts

Versions = (opts={}) ->
  opts.module_id or= Modules!.id

  opts.version_name or= if opts.development
    "scm-#{next_counter "version"}"
  else
    "0.0.0-#{next_counter "version"}"

  opts.rockspec_fname = "some_module-#{opts.version_name}.rockspec"
  opts.rockspec_key = "/spec/#{opts.rockspec_fname}"

  assert Model.create models.Versions, opts

Rocks = (opts={}) ->
  opts.version_id or= Versions!.id
  opts.arch or= "arch_#{next_counter "arch"}"

  opts.rock_fname = "some_module-#{opts.arch}.rock"
  opts.rock_key = "/spec/#{opts.rock_fname}"

  assert Model.create models.Rocks, opts

{ :next_counter, :next_email, :Users, :Modules, :Versions, :Rocks }
