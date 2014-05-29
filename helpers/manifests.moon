
import insert from table
import find_all_in_batches from require "helpers.models"

persist = require "ext.luarocks.persist"

import
  Versions
  Rocks
  from require "models"

import
  parse_version
  parse_dep
  match_constraints
  from require "ext.luarocks.deps"

-- fills modules with versions and rocks
preload_modules = (mods) ->
  mod_ids = [mod.id for mod in *mods]
  versions = find_all_in_batches Versions, mod_ids, {
    key: "module_id"
    fields: "id, module_id, version_name, lua_version, development"
  }

  version_ids = [v.id for v in *versions]
  if next version_ids
    rocks = find_all_in_batches Rocks, version_ids, {
      key: "version_id"
      fields: "version_id, arch"
    }

    versions_by_id = {v.id, v for v in *versions}
    for rock in *rocks
      v = versions_by_id[rock.version_id]
      if v.rocks
        insert v.rocks, rock
      else
        v.rocks = { rock }

  mods_by_id = {mod.id, mod for mod in *mods}
  for v in *versions
    m = mods_by_id[v.module_id]
    if m.versions
      insert m.versions, v
    else
      m.versions = { v }

  mods

-- render the manifest with no queries
render_manifest = (modules, filter_version=nil, development=nil) =>
  @res.headers["Content-type"] = "text/x-lua"

  repository = {}

  if filter_version
    filter_version = parse_version filter_version

  for mod in *modules
    mod_tbl = {}

    continue unless mod.versions
    for version in *mod.versions
      if development != nil
        continue if version.development != development

      if filter_version and version.lua_version
        dep = parse_dep version.lua_version
        continue unless match_constraints filter_version, dep.constraints

      arches = { {arch: "rockspec"} }
      mod_tbl[version.version_name] = arches

      continue unless version.rocks
      for {:arch} in *version.rocks
        insert arches, {:arch}

    if next mod_tbl
      repository[mod.name] = mod_tbl


  layout: false, persist.save_from_table_to_string {
    :repository

    commands: {}
    modules: {}
  }


{ :preload_modules, :render_manifest }
