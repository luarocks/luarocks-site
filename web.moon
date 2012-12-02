
http = require "lapis.nginx.http"
db = require "lapis.nginx.postgres"

lapis = require "lapis.init"
bucket = require "secret.storage_bucket"

persist = require "luarocks.persist"

import respond_to from require "lapis.application"
import Users, Modules, Versions from require "models"

import concat, insert from table

require "moon"

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


render_manifest = (modules) =>
  mod_ids = [mod.id for mod in *modules]

  repository = {}
  if next mod_ids
    mod_ids = concat mod_ids, ", "
    versions = Versions\select "where module_id in (#{mod_ids})"

    module_to_versions = setmetatable {}, __index: (key) =>
      with t = {} do @[key] = t

    for v in *versions
      insert module_to_versions[v.module_id], v

    for mod in *modules
      vtbl = {}
      for v in *module_to_versions[mod.id]
        vtbl[v.version_name] = arch: "rockspec"
      repository[mod.name] = vtbl

  commands = {}
  modules = {}

  @res.headers["Content-type"] = "text/x-lua"
  layout: false, persist.save_from_table_to_string {
    :repository, :commands, :modules
  }

lapis.serve class extends lapis.Application
  layout: require "views.layout"

  @before_filter =>
    @current_user = Users\read_session @

  "/db/make": =>
    schema = require "schema"
    json: { status: schema.make_schema! }
    -- out, err = db.query "select * from pg_tables where schemaname = ?", "public"
    -- json: out

  [modules: "/modules"]: =>
    @modules = Modules\select "order by name asc"
    Users\include_in @modules, "user_id"
    render: true

  [upload_rockspec: "/upload"]: respond_to {
    GET: => render: true
    POST: =>
      assert @current_user, "Must be logged in"

      file = assert @params.rockspec_file or false, "Missing rockspec"
      spec = assert parse_rockspec file.content
      mod = assert Modules\create spec, @current_user

      key = "#{ @current_user.id}/#{filename_for_rockspec spec}"
      out = bucket\put_file_string file.content, {
        :key, mimetype: "text/x-rockspec"
      }

      unless out == 200
        mod\delete!
        error "Failed to upload file"

      version = assert Versions\create mod, spec, bucket\file_url key

      mod.current_version_id = version.id
      mod\update "current_version_id"

      { redirect_to: @url_for "module", user: @current_user.slug, module: mod.name }
  }

  [index: "/"]: => render: true

  [root_manifest: "/manifest"]: =>
    render_manifest @, {}

  [user_manifest: "/manifests/:user"]: =>
    user = assert Users\find(slug: @params.user), "Invalid user"
    render_manifest @, user\all_modules!

  [user_modules: "/modules/:user"]: =>
    "profile of #{@params.user}"

  [module: "/modules/:user/:module"]: =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @module = assert Modules\find(user_id: @user.id, name: @params.module), "Invalid module"
    @versions = Versions\select "where module_id = ? order by created_at desc", @module.id

    for v in *@versions
      if v.id == @module.current_version_id
        @current_version = v

    render: true

  [module_version: "/modules/:user/:module/*"]: =>
    "look at specific version #{@params.user} #{@params.module} #{@params.splat}"

  -- need a way to combine the routes from other applications?
  [user_login: "/login"]: respond_to {
    GET: => render: true
    POST: =>
      user, err = Users\login @params.username, @params.password

      if user
        user\write_session @
        return redirect_to: "/"

      @html -> text err
  }

  [user_register: "/register"]: respond_to {
    GET: => render: true
    POST: =>
      require "moon"
      @html ->
        text "dump:"
        pre moon.dump @params
  }

  -- TODO: make this post
  [user_logout: "/logout"]: =>
    @session.user = false
    redirect_to: "/"

  --

  [files: "/files"]: =>
    @html ->
      h2 "Files"
      ol ->
        for thing in *bucket\list!
          li ->
            a href: bucket\file_url(thing.key), thing.key
            text " (#{thing.size}) #{thing.last_modified}"

  [dump: "/dump"]: =>
    require "moon"
    @html ->
      text "#{@req.cmd_mth}:"
      pre moon.dump @params

