
DEST, SERVER = ...

SERVER or= "http://luarocks.org/repositories/rocks"
DEST or= "."

ltn12 = require "ltn12"
http = require "socket.http"

print "Copying #{SERVER} to #{DEST}"
os.execute "mkdir -p '#{DEST}'"

import parse_manifest, assert_request from require "cmd.helpers"

seen_files = {}
existing_files = do
  f = io.popen "ls '#{DEST}' | grep '\\.rock$\\|\\.rockspec$'", "r"
  with { fname, true for fname in f\read("*a")\gmatch "[^\n]+" }
    f\close!

download_manifest = (name) ->
  print "Processing #{name}"
  manifest_text = assert_request "#{SERVER}/#{name}"
  manifest = assert parse_manifest manifest_text

  with io.open "#{DEST}/#{name}", "w"
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

        url = "#{SERVER}/#{fname}"
        fname = "#{DEST}/#{fname}"

        -- skip if already exists
        if f = io.open fname, "r"
          f\close!
          continue

        io.stdout\write "Downloading #{fname}..."

        tmp_fname = "#{fname}.tmp"

        http.request {
          :url
          sink: ltn12.sink.file io.open tmp_fname, "w"
          headers: {
            "user-agent": "moonrocks_backup"
          }
        }

        os.execute "mv '#{tmp_fname}' #{fname}"
        print "done"

for m in *{ "manifest", "manifest-5.1", "manifest-5.2"}
  download_manifest m

for fname in pairs existing_files
  print "Removing #{fname}"
  os.execute "rm '#{DEST}/#{fname}'"

