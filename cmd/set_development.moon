
http = require "socket.http"
import parse_rockspec from require "helpers.uploaders"

set_development = ->
  import Versions from require "models"
  versions = Versions\select!
  print "Processing #{#versions} rockspecs"

  for v in *versions
    development = Versions\version_name_is_development v.version_name

    if development != v.development
      print "setting #{v.version_name} - dev: #{development}"
      v\update(:development)


set_development!
