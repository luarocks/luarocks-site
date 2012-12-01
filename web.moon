
http = require "lapis.nginx.http"
db = require "lapis.nginx.postgres"

lapis = require "lapis.init"
bucket = require "secret.storage_bucket"

import respond_to from require "lapis.application"
import Users, Rocks from require "models"

require "moon"

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
      file = assert @params.rockspec_file, "Missing rockspec"
      if rock = Rocks\create file.content, @current_user
        { redirect_to: @url_for "rock", user: @current_user.slug, rock: rock.name }
      else
        "<pre>" .. moon.dump rock or "FAILED"
  }

  [index: "/"]: => render: true

  [user_rocks: "/rocks/:user"]: =>
    "profile of #{@params.user}"

  [rock: "/rocks/:user/:rock"]: =>
    @user = assert Users\find(slug: @params.user), "Invalid user"
    @rock = assert Rocks\find(user_id: @user.id, name: @params.rock), "Invalid rock"
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

  [upload_file: "/upload/post"]: =>
    file = @params.some_file
    error "missing file" unless file

    out = bucket\put_file_string file.content, {
      key: file.filename
      mimetype: file["content-type"]
    }

    if out == 200
      redirect_to: @url_for"files"
    else
      @html ->
        h2 "Upload Failed"
        pre out

  [dump: "/dump"]: =>
    require "moon"
    @html ->
      text "#{@req.cmd_mth}:"
      pre moon.dump @params

