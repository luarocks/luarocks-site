
http = require "socket.http"

import run_with_server from require "lapis.cmd.nginx"
import parse_rockspec from require "helpers.uploaders"

-- grabs the rockspecs and sets the lua version in the database entry
run_with_server ->
  import Versions from require "models"
  versions = Versions\select [[where lua_version is null]]

  print "Processing #{#versions} rockspecs"

  for v in *versions
    url = v\url!
    print "Processing #{url}"
    body, status = http.request url

    if status != 200
      print " * failed with status #{status}"
      continue

    spec, err = parse_rockspec body

    unless spec
      print " * failed to parse rockspec: #{err}"
      continue

    v\update_from_spec spec
    print " * ok! #{v.lua_version}"
