
bucket = require "storage_bucket"

import assert_error, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import escape_pattern from require "lapis.util"
import assert_editable from require "helpers.apps"

import
  ManifestModules
  Manifests
  Modules
  Rocks
  Versions
  from require "models"

filename_for_rockspec = (spec) ->
  "#{spec.package\lower!}-#{spec.version\lower!}.rockspec"

parse_rock_fname = (module_name, fname) ->
  version, arch = fname\match "^#{escape_pattern(module_name)}%-(.-)%.([^.]+)%.rock$"

  unless version
    return nil, "Filename must be in format `#{module_name}-VERSION.ARCH.rock`"

  { :version, :arch }

parse_rockspec = (text) ->
  fn = loadstring text
  return nil, "Failed to parse rockspec" unless fn
  spec = {}
  setfenv fn, spec
  return nil, "Failed to eval rockspec" unless pcall(fn)

  unless spec.package
    return nil, "Invalid rockspec (missing package)"

  unless spec.version
    return nil, "Invalid rockspec (missing version)"

  spec

do_rockspec_upload = (user, rockspec_text) ->
  spec, err = parse_rockspec rockspec_text
  return nil, err unless spec

  new_module = false
  mod = Modules\find user_id: user.id, name: spec.package\lower!

  unless mod
    new_module = true
    mod, err = Modules\create spec, user
    return nil, err unless mod

  key = "#{user.id}/#{filename_for_rockspec spec}"
  out = bucket\put_file_string rockspec_text, {
    :key, mimetype: "text/x-rockspec"
  }

  unless out == 200
    mod\delete! if new_module
    return nil, "Failed to upload rockspec"

  version = Versions\find module_id: mod.id, version_name: spec.version\lower!

  if version
    -- make sure file pointer is correct
    unless version.rockspec_key == key
      version\update rockspec_key: key
    version\update_from_spec spec
  else
    version, err = Versions\create mod, spec, key
    return nil, err unless version
    mod\update current_version_id: version.id

  -- try to insert into root
  if new_module
    root_manifest = Manifests\root!
    unless ManifestModules\find manifest_id: root_manifest.id, module_id: mod.id
      ManifestModules\create root_manifest, mod

  mod, version, new_module


handle_rockspec_upload = =>
  assert_error @current_user, "Must be logged in"

  assert_valid @params, {
    { "rockspec_file", file_exists: true }
  }

  file = @params.rockspec_file

  mod, version_or_err, new_module = do_rockspec_upload @current_user, file.content
  assert_error mod, version_or_err
  mod, version_or_err, new_module


do_rock_upload = (user, mod, version, filename, rock_content) ->
  rock_info, err = parse_rock_fname mod.name, filename
  return nil, err unless rock_info

  if rock_info.version != version.version_name
    yield_error "Rock doesn't match version #{version.version_name}"

  key = "#{user.id}/#{filename}"
  out = bucket\put_file_string rock_content, {
    :key, mimetype: "application/x-rock"
  }

  unless out == 200
    return nil, "Failed to upload rock"

  Rocks\create version, rock_info.arch, key

handle_rock_upload = =>
  assert @module, "need module"
  assert @version, "need version"

  assert_editable @, @module

  assert_valid @params, {
    { "rock_file", file_exists: true }
  }

  file = @params.rock_file
  assert_error do_rock_upload @current_user, @module,
    @version, file.filename, file.content

{ :handle_rock_upload, :handle_rockspec_upload, :do_rockspec_upload,
  :do_rock_upload, :parse_rockspec }
