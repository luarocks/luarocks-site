
SERVER, USER = ...

SERVER or= "http://luarocks.org/repositories/rocks/"
USER or= "luarocks"

print "Mirroring #{SERVER} to #{USER}"

http = require "socket.http"

assert_request = (...) ->
  body, status, headers = http.request ...
  assert status == 200, "Failed to request #{...}, got #{status}"
  body, status, headers

import run_with_server from require "lapis.cmd.nginx"
import parse_rockspec from require "helpers.uploaders"

parse_manifest = (text) ->
  fn = loadstring text
  return nil, "Failed to parse manifest" unless fn

  manif = {}
  setfenv fn, manif
  return nil, "Failed to eval manifest" unless pcall(fn)

  unless manif.repository
    return nil, "Invalid manifest (missing repository)"
  
  manif

local user

run_with_server ->
  import Users from require "models"
  user = Users\find slug: USER

  import do_rockspec_upload from require "helpers.uploaders"

  unless user
    import generate_key from require "helpers.models"
    password = generate_key 30
    assert Users\create USER, password, "leafot+luarocks@gmail.com"
    print "Created #{USER} with password #{password}"

  manifest = assert_request "#{SERVER}/manifest"
  manifest = assert parse_manifest manifest

  for module_name, versions in pairs manifest.repository
    print "Processing #{module_name}"
    for version_name, rocks in pairs versions
      for {:arch} in *rocks
        if arch == "rockspec"
          rockspec = assert_request "#{SERVER}/#{module_name}-#{version_name}.rockspec"
          assert do_rockspec_upload user, rockspec
          return


