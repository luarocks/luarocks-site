
ltn12 = require "ltn12"
http = require "socket.http"

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

-- server: The base URL of the server where the manifests and rocks are hosted
-- dest: The destination directory on the local filesystem where the files will be copied
-- force: A boolean flag indicating whether to force-download files even if they already exist locally
-- checkpoint_fn: A callback function that gets called after each successful download, with the downloaded file's name as an argument
update_manifest_on_disk = (server, dest, force=false, checkpoint_fn=nil) ->
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

          unless force
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
          if checkpoint_fn
            checkpoint_fn fname, mod, rock

  for m in *{ "manifest", "manifest-5.1", "manifest-5.2", "manifest-5.3", "manifest-5.4"}
    download_manifest m

  for fname in pairs existing_files
    print "Removing #{fname}"
    full_path = "#{dest}/#{fname}"
    os.execute "rm '#{shell_escape full_path}'"

{ :update_manifest_on_disk, :parse_manifest, :assert_request }
