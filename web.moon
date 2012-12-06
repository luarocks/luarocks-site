
http = require "lapis.nginx.http"
with require "cloud_storage.http"
  .set http

db = require "lapis.nginx.postgres"

lapis = require "lapis.init"
bucket = require "storage_bucket"

persist = require "luarocks.persist"

import respond_to, capture_errors, assert_error, yield_error from require "lapis.application"
import validate, assert_valid from require "lapis.validate"
import escape_pattern from require "lapis.util"
import Users, Modules, Versions, Rocks, Manifests, ManifestModules from require "models"

import concat, insert from table

parse_rockspec = (text) ->
  fn = loadstring text, rock
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
  "#{spec.package}-#{spec.version}.rockspec"

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

lapis.serve class extends lapis.Application
  layout: require "views.layout"

  @before_filter =>
    @current_user = Users\read_session @

  "/db/make": =>
    schema = require "schema"
    schema.make_schema!
    Manifests\create "root", true
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
      assert @current_user, "Must be logged in"

      assert_valid @params, {
        { "rockspec_file", file_exists: true }
      }

      file = @params.rockspec_file
      spec = assert_error parse_rockspec file.content

      new_module = false
      mod = Modules\find user_id: @current_user.id, name: spec.package

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

      version = Versions\find module_id: mod.id, version_name: spec.version

      unless version
        version = assert Versions\create mod, spec, key
        mod.current_version_id = version.id
        mod\update "current_version_id"

      redirect_to: @url_for "module", user: @current_user, module: mod
  }

  [index: "/"]: =>
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

  load_module = =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @module = assert Modules\find(user_id: @user.id, name: @params.module), "Invalid module"
    @module.user = @user

    if @params.version
      @version = assert Versions\find({
        module_id: @module.id
        version_name: @params.version
      }), "Invalid version"

  load_manifest = (key="id") =>
    @manifest = assert Manifests\find([key]: @params.manifest), "Invalid manifest id"

  assert_editable = (thing) =>
    unless thing\allowed_to_edit @current_user
      error "Don't have permission to edit"

  [module: "/modules/:user/:module"]: =>
    load_module @
    @title = "#{@module.name}"
    @versions = Versions\select "where module_id = ? order by created_at desc", @module.id
    @manifests = @module\all_manifests!

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    render: true

  [module_version: "/modules/:user/:module/:version"]: =>
    load_module @
    @title = "#{@module.name} #{@version.version_name}"
    @rocks = Rocks\select "where version_id = ? order by arch asc", @version.id

    render: true

  [upload_rock: "/modules/:user/:module/:version/upload"]: respond_to {
    before: =>
      load_module @
      @title = "Upload Rock"

    GET: require_login =>
      assert_editable @, @module
      render: true

    POST: capture_errors =>
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
      redirect_to: @url_for "module_version", @
  }

  [add_to_manifest: "/add_to_manifest/:user/:module"]: respond_to {
    before: =>
      load_module @
      @title = "Add Module To Manifest"

    GET: require_login =>
      assert_editable @, @module

      already_in = { m.id, true for m in *@module\all_manifests! }
      @manifests = for m in *Manifests\select!
        continue if already_in[m.id]
        m

      render: true

    POST: capture_errors =>
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

    POST: =>
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

  -- need a way to combine the routes from other applications?
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

  [about: "/about"]: =>
    @title = "About"
    render: true

