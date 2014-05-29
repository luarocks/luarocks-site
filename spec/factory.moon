
models = require "models"
db = require "lapis.db"

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

  models.Users\create opts.username, opts.password, opts.email

{ :next_counter, :next_email, :Users }
