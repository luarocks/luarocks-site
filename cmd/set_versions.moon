
http = require "socket.http"

import parse_rockspec from require "helpers.uploaders"

-- grabs the rockspecs and sets the lua version in the database entry
set_versions = ->
  import Versions from require "models"
  versions = Versions\select [[where lua_version is null]]

  print "Processing #{#versions} rockspecs"

  for v in *versions
    print "Processing #{v\url!}"
    spec, err = v\get_spec!

    unless spec
      print " * failed to parse rockspec: #{err}"
      continue

    v\update_from_spec spec
    print " * ok! - version: #{v.lua_version}"


set_versions!
