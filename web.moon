
http = require "lapis.nginx.http"
db = require "lapis.nginx.postgres"

lapis = require "lapis.init"
bucket = require "secret.storage_bucket"

import respond_to from require "lapis.application"
import Users from require "models"

require "moon"

lapis.serve class extends lapis.Application
  layout: require "views.layout"

  @before_filter =>
    @current_user = Users\read_session @

  "/db/make": =>
    -- schema = require "schema"
    -- schema.make_schema!
    -- json: { status: "ok" }
    out, err = db.query "select * from pg_tables where schemaname = ?", "public"
    json: out

  [index: "/"]: => render: true

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

  [upload_file: "/upload"]: =>
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

