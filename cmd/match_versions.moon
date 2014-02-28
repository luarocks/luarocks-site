
import run_with_server from require "lapis.cmd.nginx"


import
  parse_version
  parse_dep
  match_constraints
  from require "ext.luarocks.deps"


lua_versions = {
  parse_version "5.1"
  parse_version "5.2"
}

run_with_server ->
  import Versions from require "models"
  for v in *Versions\select!
    dep = parse_dep v.lua_version

    print "#{v.rockspec_fname}: #{v.lua_version}"
    for version in *lua_versions
      print " * #{version.string}: #{match_constraints version, dep.constraints}"


