
db = require "lapis.db"
bcrypt = require "bcrypt"

bucket = require "storage_bucket"

import Model from require "lapis.db.model"
import underscore, slugify from require "lapis.util"
import concat from table

math.randomseed os.time!

local *

increment_counter = (keys, amount=1) =>
  amount = tonumber amount
  keys = {keys} unless type(keys) == "table"

  update = {}
  for key in *keys
    update[key] = db.raw"#{db.escape_identifier key} + #{amount}"

  db.update @@table_name!, update, @_primary_cond!

generate_key = do
  import random from math
  random_char = ->
    switch random 1,3
      when 1
        random 65, 90
      when 2
        random 97, 122
      when 3
        random 48, 57

  (length) ->
    string.char unpack [ random_char! for i=1,length ]

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
    if user and user\check_password password
      user
    else
      nil, "Incorrect username or password"

  @read_session: (r) =>
    if user_session = r.session.user
      user = @find user_session.id
      if user and user\salt! == user_session.key
        user

  update_password: (pass, r) =>
    @update encrypted_password: bcrypt.digest pass, bcrypt.salt 5
    @write_session r if r

  check_password: (pass) =>
    bcrypt.verify pass, @encrypted_password

  generate_password_reset: =>
    @get_data!
    with token = generate_key 30
      @data\update { password_reset_token: token }

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

  source_url: (r) => r\build_url "/manifests/#{@slug}"

  get_data: =>
    return if @data
    @data = UserData\find(@id) or UserData\create(@id)
    @data

  send_email: (subject, body) =>
    import render_html from require "lapis.html"
    import send_email from require "email"

    body_html = render_html ->
      div body
      hr!
      h4 ->
        a href: "http://rocks.moonscript.org", "MoonRocks"

    send_email @email, subject, body_html, html: true

  gravatar: (size) =>
    url = "http://www.gravatar.com/avatar/#{ngx.md5 @email}?d=identicon"
    url = url .. "&s=#{size}" if size
    url

class UserData extends Model
  @primary_key: "user_id"

  @create: (user_id) =>
    Model.create @, {
      :user_id
      data: "{}"
    }

-- a rockspec
class Versions extends Model
  @timestamp: true

  @create: (mod, spec, rockspec_key) =>
    version_name = spec.version\lower!

    if @check_unique_constraint module_id: mod.id, version_name: version_name
      return nil, "This version is already uploaded"

    Model.create @, {
      module_id: mod.id
      display_version_name: if version_name != spec.version then spec.version
      rockspec_fname: rockspec_key\match "/([^/]*)$"

      :rockspec_key, :version_name
    }

  url_key: (name) => @version_name

  url: => bucket\file_url @rockspec_key

  name_for_display: =>
    @display_version_name or @version_name

  increment_download: (counters={"downloads", "rockspec_downloads"}) =>
    increment_counter @, counters
    increment_counter Modules\load(id: @module_id), "downloads"

  delete: =>
    super!
    -- delete rockspec
    bucket\delete_file @rockspec_key

    -- remove rocks
    rocks = Rocks\select "where version_id = ?", @id
    for r in *rocks
      r\delete!

class Rocks extends Model
  @timestamp: true

  @create: (version, arch, rock_key) =>
    if @check_unique_constraint { version_id: version.id, :arch }
      return nil, "Rock already exists"

    Model.create @, {
      version_id: version.id
      rock_fname: rock_key\match "/([^/]*)$"
      :arch, :rock_key
    }

  url: => bucket\file_url @rock_key

  increment_download: =>
    increment_counter @, "downloads"
    version = @version or Versions\find id: @version_id
    version\increment_download {"downloads"}

  delete: =>
    super!
    bucket\delete_file @rock_key

class Modules extends Model
  @timestamp: true

  -- spec: parsed rockspec
  @create: (spec, user) =>
    description = spec.description or {}
    name = spec.package\lower!

    if @check_unique_constraint user_id: user.id, :name
      return nil, "Module already exists"

    Model.create @, {
      :name
      user_id: user.id
      display_name: if name != spec.package then spec.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }

  url_key: (name) => @name

  name_for_display: =>
    @display_name or @name

  format_homepage_url: =>
    return if not @homepage or @homepage == ""
    unless @homepage\match "%w+://"
      return "http://" .. homepage

    @homepage

  allowed_to_edit: (user) =>
    user and (user.id == @user_id or user\is_admin!)

  all_manifests: =>
    assocs = ManifestModules\select "where module_id = ?", @id
    manifest_ids = [db.escape_literal(a.manifest_id) for a in *assocs]

    if next manifest_ids
      Manifests\select "where id in (#{concat manifest_ids, ","}) order by name asc"
    else
      {}

  count_versions: =>
    res = db.query "select count(*) as c from versions where module_id = ?", @id
    res[1].c

  delete: =>
    super!
    -- Remove module from manifests
    db.delete ManifestModules\table_name!, module_id: @id

    -- Remove versions
    versions = Versions\select "where module_id = ? ", @id
    for v in *versions
      v\delete!

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

  @root: =>
    assert Manifests\find(id: 1), "Missing root manifest"

  allowed_to_add: (user) =>
    return false unless user
    return true if @is_open or user\is_admin!
    ManifestAdmins\find user_id: user.id, manifest_id: @id

  all_modules: =>
    assocs = ManifestModules\select "where manifest_id = ?", @id
    module_ids = [db.escape_literal(a.module_id) for a in *assocs]

    if next module_ids
      Modules\select "where id in (#{concat module_ids, ", "}) order by name asc"
    else
      {}

  source_url: (r) => r\build_url!

  url_key: (name) =>
    if name == "manifest"
      @name
    else
      @id

class ApiKeys extends Model
  @primary_key: {"user_id", "key"}
  @timestamp: true

  @generate: (user_id, source) =>
    key = generate_key 40
    @create { :user_id, :key, :source }

  url_key: => @key

{
  :Users, :UserData, :Modules, :Versions, :Rocks, :Manifests, :ManifestAdmins,
  :ManifestModules, :ApiKeys
}
