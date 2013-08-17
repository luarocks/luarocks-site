
http = require "lapis.nginx.http"
with require "cloud_storage.http"
  .set http

db = require "lapis.db"
lapis = require "lapis.init"
csrf = require "lapis.csrf"

bucket = require "storage_bucket"

persist = require "luarocks.persist"

import respond_to, capture_errors, capture_errors_json, assert_error, yield_error from require "lapis.application"
import validate, assert_valid from require "lapis.validate"
import escape_pattern, trim_filter from require "lapis.util"

import Users, UserData, Modules, Versions, Rocks, Manifests, ManifestModules, ApiKeys from require "models"

import concat, insert from table

parse_rockspec = (text) ->
  fn = loadstring text
  return nil, "Failed to parse rockspec" unless fn
  spec = {}
  setfenv fn, spec
  return nil, "Failed to eval rockspec" unless pcall(fn)

  unless spec.package
    return nil, "Invalid rockspec (missing package)"

  unless spec.version
    return nil, "Invalid rockspec (missing version)"

  spec

filename_for_rockspec = (spec) ->
  "#{spec.package\lower!}-#{spec.version\lower!}.rockspec"

parse_rock_fname = (module_name, fname) ->
  version, arch = fname\match "^#{escape_pattern(module_name)}%-(.-)%.([^.]+)%.rock$"

  unless version
    return nil, "Filename must be in format `#{module_name}-VERSION.ARCH.rock`"

  { :version, :arch }

default_table = ->
  setmetatable {}, __index: (key) =>
    with t = {} do @[key] = t

render_manifest = (modules) =>
  mod_ids = [mod.id for mod in *modules]

  repository = {}
  if next mod_ids
    mod_ids = concat mod_ids, ", "
    versions = Versions\select "where module_id in (#{mod_ids})"

    module_to_versions = default_table!
    version_to_rocks = default_table!

    version_ids = [v.id for v in *versions]
    if next version_ids
      version_ids = concat version_ids, ", "
      rocks = Rocks\select "where version_id in (#{version_ids})"
      for rock in *rocks
        insert version_to_rocks[rock.version_id], rock

    for v in *versions
      insert module_to_versions[v.module_id], v

    for mod in *modules
      vtbl = {}

      for v in *module_to_versions[mod.id]
        rtbl = {}
        insert rtbl, arch: "rockspec"
        for rock in *version_to_rocks[v.id]
          insert rtbl, arch: rock.arch

        vtbl[v.version_name] = rtbl

      repository[mod.name] = vtbl

  commands = {}
  modules = {}

  @res.headers["Content-type"] = "text/x-lua"
  layout: false, persist.save_from_table_to_string {
    :repository, :commands, :modules
  }

require_login = (fn) ->
  =>
    if @current_user
      fn @
    else
      redirect_to: @url_for"user_login"

load_module = =>
  @user = assert Users\find(slug: @params.user), "Invalid user"
  @module = assert Modules\find(user_id: @user.id, name: @params.module\lower!), "Invalid module"
  @module.user = @user

  if @params.version
    @version = assert Versions\find({
      module_id: @module.id
      version_name: @params.version\lower!
    }), "Invalid version"

  if @route_name and (@module.name != @params.module or @version and @version.version_name != @params.version)
    url = @url_for @route_name, user: @user, module: @module, version: @version
    @write status: 301, redirect_to: url
    return false

  true

load_manifest = (key="id") =>
  @manifest = assert Manifests\find([key]: @params.manifest), "Invalid manifest id"

assert_editable = (thing) =>
  unless thing\allowed_to_edit @current_user
    error "Don't have permission to edit"

generate_csrf = =>
  csrf.generate_token @, @current_user and @current_user.id

assert_csrf = =>
  csrf.assert_token @, @current_user and @current_user.id

assert_table = (val) ->
  assert_error type(val) == "table", "malformed input, expecting table"
  val

api_request = (fn) ->
  capture_errors_json =>
    @key = assert_error ApiKeys\find(key: @params.key), "Invalid key"
    @current_user = Users\find id: @key.user_id
    fn @

delete_module = respond_to {
  before: =>
    load_module @
    @title = "Delete #{@module\name_for_display!}?"

  GET: require_login =>
    assert_editable @, @module

    if @version and @module\count_versions! == 1
      return redirect_to: @url_for "delete_module", @params

    render: true

  POST: require_login capture_errors =>
    assert_csrf @
    assert_editable @, @module

    assert_valid @params, {
      { "module_name", equals: @module.name }
    }

    if @version
      if @module\count_versions! == 1
        error "can not delete only version"

      @version\delete!
      redirect_to: @url_for "module", @params
    else
      @module\delete!
      redirect_to: @url_for "index"
}

handle_rockspec_upload = =>
  assert_error @current_user, "Must be logged in"

  assert_valid @params, {
    { "rockspec_file", file_exists: true }
  }

  file = @params.rockspec_file
  spec = assert_error parse_rockspec file.content

  new_module = false
  mod = Modules\find user_id: @current_user.id, name: spec.package\lower!

  unless mod
    new_module = true
    mod = assert Modules\create spec, @current_user

  key = "#{@current_user.id}/#{filename_for_rockspec spec}"
  out = bucket\put_file_string file.content, {
    :key, mimetype: "text/x-rockspec"
  }

  unless out == 200
    mod\delete! if new_module
    error "Failed to upload rockspec"

  version = Versions\find module_id: mod.id, version_name: spec.version\lower!

  if version
    -- make sure file pointer is correct
    unless version.rockspec_key == key
      version\update rockspec_key: key
  else
    version = assert Versions\create mod, spec, key
    mod\update current_version_id: version.id

  -- try to insert into root
  if new_module
    root_manifest = Manifests\root!
    unless ManifestModules\find manifest_id: root_manifest.id, module_id: mod.id
      ManifestModules\create root_manifest, mod

  mod, version, new_module


handle_rock_upload = =>
  assert_editable @, @module

  assert_valid @params, {
    { "rock_file", file_exists: true }
  }

  file = @params.rock_file

  rock_info = assert_error parse_rock_fname @module.name, file.filename

  if rock_info.version != @version.version_name
    yield_error "Rock doesn't match version #{@version.version_name}"

  key = "#{@current_user.id}/#{file.filename}"
  out = bucket\put_file_string file.content, {
    :key, mimetype: "application/x-rock"
  }

  unless out == 200
    error "Failed to upload rock"

  Rocks\create @version, rock_info.arch, key


set_memory_usage = ->
  posix = require "posix"
  json = require "cjson"

  pid = posix.getpid "pid"
  mem = collectgarbage "count"
  time = os.time!

  ngx.shared.memory_usage\set tostring(pid), json.encode { :mem, :time }

class extends lapis.Application
  layout: require "views.layout"

  @before_filter =>
    @current_user = Users\read_session @
    @csrf_token = generate_csrf @
    pcall -> set_memory_usage!

  [info: "/info"]: =>
    json = require "cjson"
    dict = ngx.shared.memory_usage

    @workers = for pid in *dict\get_keys!
      with w = json.decode dict\get pid
        w.pid = pid

    table.sort @workers, (a,b) ->
      b.time < a.time

    render: true

  "/admin/db/make": =>
    schema = require "schema"
    schema.make_schema!
    Manifests\create "root", true
    json: { status: "ok" }

  "/admin/db/migrate": =>
    import run_migrations from require "lapis.db.migrations"
    run_migrations require "migrations"
    json: { status: "ok" }

  [modules: "/modules"]: =>
    @title = "All Modules"
    @modules = Modules\select "order by name asc"
    Users\include_in @modules, "user_id"
    render: true

  [upload_rockspec: "/upload"]: respond_to {
    before: =>
      @title = "Upload Rockspec"

    GET: require_login =>
      render: true

    POST: capture_errors =>
      assert_csrf @
      mod, version = handle_rockspec_upload @
      redirect_to: @url_for "module", user: @current_user, module: mod
  }

  [index: "/"]: =>
    @page_description = "A website for submitting and distributing Lua rocks"

    @recent_modules = Modules\select "order by created_at desc limit 5"
    Users\include_in @recent_modules, "user_id"
    @popular_modules = Modules\select "order by downloads desc limit 5"
    Users\include_in @popular_modules, "user_id"

    render: true

  [root_manifest: "/manifest"]: =>
    modules = Manifests\root!\all_modules!
    render_manifest @, modules

  "/manifests/:user": => redirect_to: @url_for("user_manifest", user: @params.user)

  [user_manifest: "/manifests/:user/manifest"]: =>
    user = assert Users\find(slug: @params.user), "Invalid user"
    render_manifest @, user\all_modules!

  [user_profile: "/modules/:user"]: =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @title = "#{@user.username}'s Modules"
    @modules = Modules\select "where user_id = ? order by name asc", @user.id
    for mod in *@modules
      mod.user = @user

    render: true

  [module: "/modules/:user/:module"]: =>
    return unless load_module @

    @title = "#{@module\name_for_display!}"
    @page_description = @module.summary if @module.summary

    @versions = Versions\select "where module_id = ? order by created_at desc", @module.id
    @manifests = @module\all_manifests!

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    render: true

  [edit_module: "/edit/modules/:user/:module"]: respond_to {
    before: =>
      load_module @
      assert_editable @, @module

      @title = "Edit '#{@module\name_for_display!}'"

    GET: =>
      render: true

    POST: =>
      changes = @params.m

      trim_filter changes, {
        "license", "description", "display_name", "homepage"
      }, db.NULL

      @module\update changes
      redirect_to: @url_for("module", @)
  }

  [module_version: "/modules/:user/:module/:version"]: =>
    return unless load_module @

    @title = "#{@module\name_for_display!} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    render: true

  [delete_module: "/delete/:user/:module"]: delete_module
  [delete_module_version: "/delete/:user/:module/:version"]: delete_module

  [upload_rock: "/modules/:user/:module/:version/upload"]: respond_to {
    before: =>
      load_module @
      @title = "Upload Rock"

    GET: require_login =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
      assert_csrf @
      handle_rock_upload @
      redirect_to: @url_for "module_version", @
  }

  [add_to_manifest: "/add_to_manifest/:user/:module"]: respond_to {
    before: =>
      load_module @
      @title = "Add Module To Manifest"

      already_in = { m.id, true for m in *@module\all_manifests! }
      @manifests = for m in *Manifests\select!
        continue if already_in[m.id]
        m

    GET: require_login =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_editable @, @module

      manifest_id = assert_error @params.manifest_id, "Missing manifest_id"
      manifest = assert_error Manifests\find(id: manifest_id), "Invalid manifest id"

      unless manifest\allowed_to_add @current_user
        yield_error "Don't have permission to add to manifest"

      assert ManifestModules\create manifest, @module
      redirect_to: @url_for("module", @)
  }


  [remove_from_manifest: "/remove_from_manifest/:user/:module/:manifest"]: respond_to {
    before: =>
      load_module @
      load_manifest @

    GET: require_login =>
      assert_editable @, @module
      @title = "Remove Module From Manifest"

      assert ManifestModules\find({
        manifest_id: @manifest.id
        module_id: @module.id
      }), "Module is not in manifest"

      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_editable @, @module

      ManifestModules\remove @manifest, @module
      redirect_to: @url_for("module", @)
  }

  [manifest: "/m/:manifest"]: =>
    load_manifest @, "name"
    @title = "#{@manifest.name} Manifest"
    @modules = @manifest\all_modules!
    Users\include_in @modules, "user_id"

    render: true

  [user_login: "/login"]: respond_to {
    before: =>
      @title = "Login"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_valid @params, {
        { "username", exists: true }
        { "password", exists: true }
      }

      user = assert_error Users\login @params.username, @params.password
      user\write_session @
      redirect_to: @url_for"index"
  }

  [user_register: "/register"]: respond_to {
    before: =>
      @title = "Register Account"

    GET: =>
      render: true

    POST: capture_errors =>
      assert_csrf @
      assert_valid @params, {
        { "username", exists: true, min_length: 2, max_length: 25 }
        { "password", exists: true, min_length: 2 }
        { "password_repeat", equals: @params.password }
        { "email", exists: true, min_length: 3 }
      }

      {:username, :password, :email } = @params
      user = assert_error Users\create username, password, email

      user\write_session @
      redirect_to: @url_for"index"
  }

  -- TODO: make this post
  [user_logout: "/logout"]: =>
    @session.user = false
    redirect_to: "/"

  validate_reset_token = =>
    if @params.token
      assert_valid @params, {
        { "id", is_integer: true }
      }

      @user = assert_error Users\find(@params.id), "invalid token"
      @user\get_data!
      assert_error @user.data.password_reset_token == @params.token, "invalid token"
      @token = @params.token
      true

  [user_forgot_password: "/user/forgot_password"]: respond_to {
    GET: capture_errors =>
      validate_reset_token @
      render: true

    POST: capture_errors =>
      assert_csrf @

      if validate_reset_token @
        assert_valid @params, {
          { "password", exists: true, min_length: 2 }
          { "password_repeat", equals: @params.password }
        }
        @user\update_password @params.password, @
        @user.data\update { password_reset_token: db.NULL }
        redirect_to: @url_for"index"
      else
        assert_valid @params, {
          { "email", exists: true, min_length: 3 }
        }

        user = assert_error Users\find(email: @params.email),
          "don't know anyone with that email"

        token = user\generate_password_reset!

        reset_url = @build_url @url_for"user_forgot_password",
          query: "token=#{token}&id=#{user.id}"

        user\send_email "Reset your password", ->
          h2 "Reset Your Password"
          p "Someone attempted to reset your password. If that person was you, click the link below to update your password. If it wasn't you then you don't have to do anything."
          p ->
            a href: reset_url, reset_url

        redirect_to: @url_for"user_forgot_password" .. "?sent=true"
  }

  [user_settings: "/settings"]: require_login respond_to {
    before: =>
      @user = @current_user
      @user\get_data!
      @title = "User Settings"

    GET: =>
      @api_keys = ApiKeys\select "where user_id = ?", @user.id
      render: true

    POST: capture_errors =>
      assert_csrf @

      if passwords = @params.password
        assert_table passwords
        trim_filter passwords

        assert_valid passwords, {
          { "new_password", exists: true, min_length: 2 }
          { "new_password_repeat", equals: passwords.new_password }
        }

        assert_error @user\check_password(passwords.current_password),
          "Invalid old password"

        @user\update_password passwords.new_password, @

      redirect_to: @url_for"user_settings" .. "?password_reset=true"
  }

  [new_api_key: "/api_keys/new"]: require_login respond_to {
    POST: capture_errors {
      on_error: => redirect_to: @url_for "user_settings"

      =>
        assert_csrf @
        ApiKeys\generate @current_user.id
        redirect_to: @url_for "user_settings"
    }
  }

  [delete_api_key: "/api_key/:key/delete"]: require_login capture_errors {
    on_error: => redirect_to: @url_for "user_settings"

    respond_to {
      before: =>
        @key = ApiKeys\find user_id: @current_user.id, key: @params.key
        assert_error @key, "Invalid key"

      GET: => render: true

      POST: =>
        assert_csrf @
        @key\delete!
        redirect_to: @url_for "user_settings"
    }
  }

  "/api/tool_version": =>
    config = require"lapis.config".get!
    json: { version: config.tool_version }

  -- Get status of key
  "/api/1/:key/status": api_request =>
    json: { user_id: @current_user.id, created_at: @key.created_at }

  "/api/1/:key/modules": api_request =>
    json: { modules: @current_user\all_modules! }

  "/api/1/:key/check_rockspec": api_request =>
    assert_valid @params, {
      { "package", exists: true }
      { "version", exists: true }
    }

    module = Modules\find user_id: @current_user.id, name: @params.package\lower!
    version = if module
      Versions\find module_id: module.id, version_name: @params.version\lower!

    json: { :module, :version }

  "/api/1/:key/upload": api_request =>
    module, version, is_new = handle_rockspec_upload @

    manifest_modules = ManifestModules\select "where module_id = ?", module.id
    Manifests\include_in manifest_modules, "manifest_id"

    manifests = [m.manifest for m in *manifest_modules]
    module_url = @build_url @url_for "module", user: @current_user, :module
    json: { :module, :version, :module_url, :manifests, :is_new }

  "/api/1/:key/upload_rock/:version_id": api_request =>
    @version = assert_error Versions\find(id: @params.version_id), "invalid version"
    @module = Modules\find id: @version.module_id
    rock = handle_rock_upload @
    json: { :rock }

  [about: "/about"]: =>
    @title = "About"
    render: true

  [changes: "/changes"]: =>
    @title = "Changes"
    render: true

