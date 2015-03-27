
bucket = require "storage_bucket"

import assert_error, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import escape_pattern from require "lapis.util"
import assert_editable from require "helpers.app"
import strip_non_ascii from require "helpers.strings"

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
  -- remove #! if it's there
  text = text\gsub "^%#[^\n]*", ""

  fn = loadstring text
  return nil, "Failed to parse rockspec" unless fn
  spec = {}
  setfenv fn, spec

  -- disable jit otherwise the offending code might be compiled and stop
  -- sending debug events
  jit and jit.off fn

  co = coroutine.create fn
  lines = 0

  check = ->
    lines += 1
    error "too many lines evaluated" if lines > 40

  -- luajit does not appear to let you set debug hook on coroutine, it just
  -- applies globally. We do it anyway incase this is ever fixed. Additionally
  -- it's impossible to capture the error raised in a hook, so it just forces
  -- 500 from openresty
  debug.sethook co, check, "l"
  status = pcall -> assert coroutine.resume co
  debug.sethook co

  unless status
    return nil, "Failed to eval rockspec"

  unless spec.package
    return nil, "Invalid rockspec (missing package)"

  if spec.package == ""
    return nil, "Invalid rockspec (blank package)"

  unless strip_non_ascii(spec.package) == spec.package
    return nil, "Invalid rockspec (invalid package name, ascii only)"

  unless spec.version
    return nil, "Invalid rockspec (missing version)"

  if spec.version == ""
    return nil, "Invalid rockspec (blank version)"

  unless strip_non_ascii(spec.version) == spec.version
    return nil, "Invalid rockspec (invalid version name, ascii only)"

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

  new_version = false

  version = Versions\find module_id: mod.id, version_name: spec.version\lower!

  if version
    -- make sure file pointer is correct
    unless version.rockspec_key == key
      version\update rockspec_key: key
    version\update_from_spec spec
  else
    version, err = Versions\create mod, spec, key
    return nil, err unless version
    new_version = true
    mod\update current_version_id: version.id

  -- try to insert into root
  if new_module
    root_manifest = Manifests\root!
    unless ManifestModules\find manifest_id: root_manifest.id, module_id: mod.id
      ManifestModules\create root_manifest, mod

  -- purge on additions
  if new_module or new_version
    mod\purge_manifests!

  mod, version, new_module, new_version


handle_rockspec_upload = =>
  assert_error @current_user, "Must be logged in"

  assert_valid @params, {
    { "rockspec_file", file_exists: true }
  }

  file = @params.rockspec_file

  mod, version_or_err, new_mod, new_ver = do_rockspec_upload @current_user, file.content
  assert_error mod, version_or_err
  mod, version_or_err, new_mod, new_ver

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

  if Rocks\create version, rock_info.arch, key
    mod\purge_manifests!

  true

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
