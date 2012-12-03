
db = require "lapis.db"
bcrypt = require "bcrypt"

bucket = require "secret.storage_bucket"

import Model from require "lapis.db.model"
import slugify, underscore from require "lapis.util"
import concat from table

local Modules, Versions, Users, Rocks, Manifests, ManifestModules, ManifestAdmins

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

  url_key: (name) => @slug

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29

  all_modules: =>
    Modules\select "where user_id = ?", @id

  is_admin: => @flags == 1

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

  url_key: (name) => @version_name

  rockspec_url: =>
    bucket\file_url @rockspec_key

  filename: =>
    @rockspec_key\match "/([^/]*)$"

  increment_download: =>
    increment_counter @, {"downloads", "rockspec_downloads"}
    increment_counter Modules\load(id: @module_id), {"downloads"}


class Rocks extends Model
  @timestamp: true

  @create: (version, arch, rock_key) =>
    if @check_unique_constraint { version_id: version.id, :arch }
      return nil, "Rock already exists"

    Model.create @, {
      version_id: version.id
      :arch, :rock_key
    }

  filename: =>
    @rock_key\match "/([^/]*)$"

  rock_url: =>
    bucket\file_url @rock_key

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

  url_key: (name) => @name

  allowed_to_edit: (user) =>
    user and user.id == @user_id or user\is_admin!

  all_manifests: =>
    assocs = ManifestModules\select "where module_id = ?", @id
    manifest_ids = [db.escape_literal(a.manifest_id) for a in *assocs]

    if next manifest_ids
      Manifests\select "where id in (#{concat manifest_ids, ","}) order by name asc"
    else
      {}

class ManifestAdmins extends Model
  @primary_key: {"user_id", "manifest_id"}

  @create: (manifest, user, is_owner=false) =>
    Model.create @ {
      manifest_id: manifest.id
      user_id: user.id
      :is_owner
    }

  @remove: (manifest, user) =>
    assert user.id and manifest.id, "Missing user/manifest"
    db.delete @@table_name!, {
      manifest_id: manifest.id
      user_id: user.id
    }

class ManifestModules extends Model
  @primary_key: {"manifest_id", "module_id"}

  @create: (manifest, mod) =>
    if @check_unique_constraint manifest_id: manifest.id, module_name: mod.name
      return nil, "Manifest already has a module named `#{mod.name}`"

    Model.create @, {
      manifest_id: manifest.id
      module_id: mod.id
      module_name: mod.name
    }

  @remove: (manifest, mod) =>
    assert mod.id and manifest.id, "Missing module/manifest"
    db.delete @@table_name!, {
      manifest_id: manifest.id
      module_id: mod.id
    }

class Manifests extends Model
  @create: (name, is_open=false) =>
    if @check_unique_constraint "name", name
      return nil, "Manifest name already taken"

    Model.create @, { :name, :is_open }

  allowed_to_add: (user) =>
    return false unless user
    return true if @is_open or user\is_admin!
    ManifestAdmins\find user_id: user.id, manifest_id: @id

{
  :Users, :Modules, :Versions, :Rocks, :Manifests, :ManifestAdmins
  :ManifestModules
}
