
ltn12 = require "ltn12"
http = require "socket.http"

MANIFESTS = {
 "manifest"
 "manifest-5.1"
 "manifest-5.2"
 "manifest-5.3"
 "manifest-5.4"
 "manifest-5.5"
}

import shell_escape from require "lapis.cmd.path"

assert_request = (...) ->
  body, status, headers = http.request ...
  assert status == 200, "Failed to request #{...}, got #{status}"
  body, status, headers

parse_manifest = (text) ->
  fn = loadstring text
  return nil, "Failed to parse manifest" unless fn

  manif = {}
  setfenv fn, manif
  return nil, "Failed to eval manifest" unless pcall(fn)

  unless manif.repository
    return nil, "Invalid manifest (missing repository)"

  manif

render_index = (opts={}) ->
  import render_html from require "lapis.html"

  page_title = if opts.development
    "LuaRocks Mirror - Dev Manifest"
  else
    "LuaRocks Mirror"

  render_html ->
    raw "<!DOCTYPE html>"
    html ->
      head ->
        meta charset: "utf-8"
        meta name: "viewport", content: "width=device-width, initial-scale=1"
        title page_title
        style [[
          body {
            font-family: sans-serif;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
          }
          h1 { color: #333; }
          ul { list-style: none; padding: 0; }
          li { margin: 8px 0; }
          a { color: #2563eb; text-decoration: none; }
          a:hover { text-decoration: underline; }
          code { background: #f3f4f6; padding: 2px 6px; border-radius: 3px; }
          pre { white-space: pre-wrap; word-break: break-all; }
          .info { color: #666; margin-bottom: 30px; }
        ]]
      body ->
        h1 page_title
        p class: "info", ->
          text "This is a static mirror of the "
          a href: "https://luarocks.org", "LuaRocks"
          text " package repository. Use this mirror by configuring your "
          code "luarocks"
          text " client:"
        pre ->
          code ->
            text "luarocks install --server="
            span id: "mirror-host"
            text " <rock-name>"
        script ->
          raw [[document.getElementById('mirror-host').textContent = window.location.href.replace(/\/?(index\.html)?$/, '')]]

        h2 "Manifest Files"
        ul ->
          for m in *MANIFESTS
            li ->
              a href: m, m
              text " ("
              a href: "#{m}.json", "json"
              text ")"
        p class: "info", ->
          text "For more information, visit "
          a href: "https://luarocks.org", "luarocks.org"
          text "."

-- server: The base URL of the server where the manifests and rocks are hosted
-- dest: The destination directory on the local filesystem where the files will be copied
-- opts: Options table with:
--   force: A boolean flag indicating whether to force-download files even if they already exist locally
--   checkpoint_fn: A callback function that gets called after each successful download
--   development: A boolean flag indicating if this is a development manifest mirror
update_manifest_on_disk = (server, dest, opts={}) ->
  print "Copying #{server} to #{dest}"
  os.execute "mkdir -p '#{shell_escape dest}'"

  seen_files = {}
  existing_files = do
    f = io.popen "ls '#{shell_escape dest}' | grep '\\.rock$\\|\\.rockspec$'", "r"
    with { fname, true for fname in f\read("*a")\gmatch "[^\n]+" }
      f\close!

  download_manifest = (name) ->
    print "Processing #{name}"
    manifest_text = assert_request "#{server}/#{name}"
    manifest = assert parse_manifest manifest_text

    with io.open "#{dest}/#{name}", "w"
      \write manifest_text
      \close!

    json_text = assert_request "#{server}/#{name}.json"
    with io.open "#{dest}/#{name}.json", "w"
      \write json_text
      \close!

    for mod_name, mod in pairs manifest.repository
      for version_name, rocks in pairs mod
        for rock in *rocks
          fname = if rock.arch == "rockspec"
            "#{mod_name}-#{version_name}.rockspec"
          else
            "#{mod_name}-#{version_name}.#{rock.arch}.rock"

          -- skip if already processed
          continue if seen_files[fname]
          existing_files[fname] = nil
          seen_files[fname] = true

          url = "#{server}/#{fname}"
          fname = "#{dest}/#{fname}"

          unless opts.force
            -- skip if already exists
            if f = io.open fname, "r"
              f\close!
              continue

          io.stdout\write "Downloading #{fname}..."

          tmp_fname = "#{fname}.tmp"

          res, status = http.request {
            :url
            sink: ltn12.sink.file io.open tmp_fname, "w"
            headers: {
              "user-agent": "moonrocks_backup"
            }
          }

          if (not res) or (type(status) == "number" and status >= 400)
            seen_files[fname] = nil
            os.execute "rm '#{shell_escape tmp_fname}'"
            print "failed"
            continue

          os.execute "mv '#{shell_escape tmp_fname}' '#{shell_escape fname}'"
          print "done"
          if opts.checkpoint_fn
            opts.checkpoint_fn fname, mod, rock

  for m in *MANIFESTS
    download_manifest m

  for fname in pairs existing_files
    print "Removing #{fname}"
    full_path = "#{dest}/#{fname}"
    os.execute "rm '#{shell_escape full_path}'"

  -- Write index.html
  index_path = "#{dest}/index.html"
  f = assert io.open index_path, "w"
  f\write render_index development: opts.development
  f\close!
  print "Generated #{index_path}"

{ :update_manifest_on_disk, :parse_manifest, :assert_request, :render_index }
