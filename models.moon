
db = require "lapis.db"
bcrypt = require "bcrypt"

bucket = require "secret.storage_bucket"

import Model from require "lapis.db.model"
import slugify, underscore from require "lapis.util"

local Modules, Versions, Users

increment_counter = (keys, amount=1) =>
  amount = tonumber amount
  keys = {keys} unless type(keys) == "table"

  update = {}
  for key in *keys
    update[key] = db.raw"#{db.escape_identifier key} + #{amount}"

  db.update @@table_name!, update, @_primary_cond!

class Users extends Model
  @timestamp: true

  @create: (username, password, email) =>
    encrypted_password = bcrypt.digest password, bcrypt.salt 5
    slug = slugify username

    if @check_unique_constraint "username", username
      return nil, "Username already taken"

    if @check_unique_constraint "slug", slug
      return nil, "Username already taken"

    if @check_unique_constraint "email", email
      return nil, "Email already taken"

    Model.create @, {
      :username, :encrypted_password, :email, :slug
    }

  @login: (username, password) =>
    user = Users\find { :username }
    if user and bcrypt.verify password, user.encrypted_password
      user
    else
      nil, "Incorrect username or password"

  @read_session: (r) =>
    if user_session = r.session.user
      user = @find user_session.id
      if user\salt! == user_session.key
        user

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29

  all_modules: =>
    Modules\select "where user_id = ?", @id

class Versions extends Model
  @timestamp: true

  @create: (mod, spec, rockspec_key) =>
    if @check_unique_constraint module_id: mod.id, version_name: spec.version
      return nil, "This version is already uploaded"

    Model.create @, {
      module_id: mod.id
      version_name: spec.version
      :rockspec_key
    }

  rockspec_url: =>
    bucket\file_url @rockspec_key

  increment_download: =>
    increment_counter @, {"downloads", "rockspec_downloads"}

class Modules extends Model
  @timestamp: true

  -- spec: parsed rockspec
  @create: (spec, user) =>
    description = spec.description or {}

    if @check_unique_constraint user_id: user.id, name: spec.package
      return nil, "Module already exists"

    Model.create @, {
      user_id: user.id
      name: spec.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }

{ :Users, :Modules, :Versions }
