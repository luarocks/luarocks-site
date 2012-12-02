
http = require "lapis.nginx.http"
db = require "lapis.nginx.postgres"

lapis = require "lapis.init"
bucket = require "secret.storage_bucket"

persist = require "luarocks.persist"

import respond_to from require "lapis.application"
import Users, Rocks, Versions from require "models"

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


render_manifest = (rocks) =>
  rock_ids = [rock.id for rock in *rocks]
  repository = {}
  if next rock_ids
    rock_ids = concat rock_ids, ", "
    versions = Versions\select "where rock_id in (#{rock_ids})"

    rock_to_versions = setmetatable {}, __index: (key) =>
      with t = {} do @[key] = t

    for v in *versions
      insert rock_to_versions[v.rock_id], v

    for rock in *rocks
      vtbl = {}
      for v in *rock_to_versions[rock.id]
        vtbl[v.version_name] = arch: v.arch
      repository[rock.name] = vtbl

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
    schema.make_schema!
    json: { status: "ok" }
    -- out, err = db.query "select * from pg_tables where schemaname = ?", "public"
    -- json: out

  [rocks: "/rocks"]: =>
    @rocks = Rocks\select "order by name asc"
    Users\include_in @rocks, "user_id"
    render: true

  [upload_rockspec: "/upload"]: respond_to {
    GET: => render: true
    POST: =>
      assert @current_user, "Must be logged in"

      file = assert @params.rockspec_file or false, "Missing rockspec"
      spec = assert parse_rockspec file.content
      rock = assert Rocks\create spec, @current_user

      key = "#{ @current_user.id}/#{filename_for_rockspec spec}"
      out = bucket\put_file_string file.content, {
        :key, mimetype: "text/x-rockspec"
      }

      unless out == 200
        rock\delete!
        error "Failed to upload file"

      version = assert Versions\create rock, spec, bucket\file_url key

      rock.current_version_id = version.id
      rock\update "current_version_id"

      { redirect_to: @url_for "rock", user: @current_user.slug, rock: rock.name }
  }

  [index: "/"]: => render: true

  [root_manifest: "/manifest"]: =>
    render_manifest @, {} -- Rocks\select!

  [user_manifest: "/manifests/:user"]: =>
    user = assert Users\find(slug: @params.user), "Invalid user"
    rocks = user\all_rocks!

    render_manifest @, rocks

  [user_rocks: "/rocks/:user"]: =>
    "profile of #{@params.user}"

  [rock: "/rocks/:user/:rock"]: =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @rock = assert Rocks\find(user_id: @user.id, name: @params.rock), "Invalid rock"
    @versions = Versions\select "where rock_id = ? order by created_at desc", @rock.id

    for v in *@versions
      if v.id == @rock.current_version_id
        @current_version = v

    render: true

  [rock_version: "/rocks/:user/:rock/*"]: =>
    "look at specific version #{@params.user} #{@params.rock} #{@params.splat}"

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

