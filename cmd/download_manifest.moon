
DEST, SERVER = ...

SERVER or= "http://luarocks.org/repositories/rocks"
DEST or= "."

ltn12 = require "ltn12"
http = require "socket.http"

print "Copying #{SERVER} to #{DEST}"

import parse_manifest, assert_request from require "cmd.helpers"

manifest = assert_request "#{SERVER}/manifest"
manifest = assert parse_manifest manifest

for mod_name, mod in pairs manifest.repository
  for version_name, rocks in pairs mod
    for rock in *rocks
      fname = if rock.arch == "rockspec"
        "#{mod_name}-#{version_name}.rockspec"
      else
        "#{mod_name}-#{version_name}.#{rock.arch}.rock"

      url = "#{SERVER}/#{fname}"
      fname = "#{DEST}/#{fname}"

      print url

      if f = io.open fname, "r"
        f\close!
        continue

      io.stdout\write "Downloading..."
      http.request {
        :url
        sink: ltn12.sink.file io.open fname, "w"
      }
      print "done"

