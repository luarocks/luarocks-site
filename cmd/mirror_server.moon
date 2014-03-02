
SERVER, USER = ...

SERVER or= "http://luarocks.org/repositories/rocks"
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

-- attempt to convert latin-1 chars to utf8
fix_encoding = (str) ->
  import insert from table
  buffer = {}
  changed = false

  bytes = [string.byte c for c in str\gmatch "."]
  for i, b in ipairs bytes
    prev = bytes[i - 1]
    after = bytes[i + 1]

    if b > 126 and (not prev or prev < 126) and (not after or after < 126)
      changed = true
      insert buffer, 194 -- insert latin1 leading byte

    insert buffer, b

  if changed
    table.concat([string.char(b) for b in *buffer]), true
  else
    str, false


local user

run_with_server ->
  import Users from require "models"
  user = Users\find slug: USER

  import do_rockspec_upload, do_rock_upload from require "helpers.uploaders"

  unless user
    import generate_key from require "helpers.models"
    password = generate_key 30
    assert Users\create USER, password, "leafot+luarocks@gmail.com"
    print "Created #{USER} with password #{password}"

  user_modules = user\all_modules!
  modules_by_name = {mod.name, mod for mod in *user_modules}

  manifest = assert_request "#{SERVER}/manifest"
  manifest = assert parse_manifest manifest

  for module_name, versions in pairs manifest.repository
    print "Processing #{module_name}"
    existing_mod = modules_by_name[module_name]
    existing_versions = if existing_mod
      {v.version_name, v for v in *existing_mod\get_verions!}
    else
      {}

    for version_name, rocks in pairs versions
      existing_ver = existing_versions[version_name]

      io.stdout\write " * #{version_name} rockspec"
      mod, version = if existing_ver
        print " - skipped"
        existing_mod, existing_ver
      else
        print " - uploading"
        rockspec, status = http.request "#{SERVER}/#{module_name}-#{version_name}.rockspec"

        if status != 200
          print "  Skipping due to missing rockspec"
          continue

        rockspec, changed_enc = fix_encoding rockspec
        mod, version = assert do_rockspec_upload user, rockspec

      existing_rocks = if existing_ver
        {rock.arch, rock for rock in *existing_ver\get_rocks!}
      else
        {}

      for {:arch} in *rocks
        continue if arch == "rockspec"
        io.stdout\write " * #{version_name} #{arch}"
        if existing_rocks[arch]
          print " - skipped"
        else
          print " - uploading"
          fname = "#{module_name}-#{version_name}.#{arch}.rock"
          rock = assert_request "#{SERVER}/#{fname}"
          do_rock_upload user, mod, version, fname, rock


