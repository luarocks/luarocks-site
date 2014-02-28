
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

handle_rockspec_upload = =>
  assert_error @current_user, "Must be logged in"

  assert_valid @params, {
    { "rockspec_file", file_exists: true }
  }

  file = @params.rockspec_file
  spec = assert_error parse_rockspec file.content

  new_module = false
  mod = Modules\find user_id: @current_user.id, name: spec.package\lower!

  unless mod
    new_module = true
    mod = assert Modules\create spec, @current_user

  key = "#{@current_user.id}/#{filename_for_rockspec spec}"
  out = bucket\put_file_string file.content, {
    :key, mimetype: "text/x-rockspec"
  }

  unless out == 200
    mod\delete! if new_module
    error "Failed to upload rockspec"

  version = Versions\find module_id: mod.id, version_name: spec.version\lower!

  if version
    -- make sure file pointer is correct
    unless version.rockspec_key == key
      version\update rockspec_key: key
    version\update_from_spec spec
  else
    version = assert Versions\create mod, spec, key
    mod\update current_version_id: version.id

  -- try to insert into root
  if new_module
    root_manifest = Manifests\root!
    unless ManifestModules\find manifest_id: root_manifest.id, module_id: mod.id
      ManifestModules\create root_manifest, mod

  mod, version, new_module


handle_rock_upload = =>
  assert_editable @, @module

  assert_valid @params, {
    { "rock_file", file_exists: true }
  }

  file = @params.rock_file

  rock_info = assert_error parse_rock_fname @module.name, file.filename

  if rock_info.version != @version.version_name
    yield_error "Rock doesn't match version #{@version.version_name}"

  key = "#{@current_user.id}/#{file.filename}"
  out = bucket\put_file_string file.content, {
    :key, mimetype: "application/x-rock"
  }

  unless out == 200
    error "Failed to upload rock"

  Rocks\create @version, rock_info.arch, key


{ :handle_rock_upload, :handle_rockspec_upload, :parse_rockspec }
