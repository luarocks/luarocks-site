
import Modules, Versions, Rocks from require "models"
import is_valid_manifest_string from require "helpers.uploaders"

print "Scanning for invalid names in database..."
print ""

-- Check modules
print "=== MODULES WITH INVALID NAMES ==="
bad_modules = 0
for mod in *Modules\select!
  unless is_valid_manifest_string mod.name
    bad_modules += 1
    user = mod\get_user!
    print "Module ID: #{mod.id}"
    print "  Name: '#{mod.name}'"
    print "  User: #{user and user.username or 'unknown'} (id: #{mod.user_id})"
    print "  URL: https://luarocks.org/modules/#{user and user.username or mod.user_id}/#{mod.name}"
    print ""

print "Total modules with invalid names: #{bad_modules}"
print ""

-- Check versions
print "=== VERSIONS WITH INVALID NAMES ==="
bad_versions = 0
for version in *Versions\select!
  unless is_valid_manifest_string version.version_name
    bad_versions += 1
    mod = version\get_module!
    user = mod and mod\get_user!
    print "Version ID: #{version.id}"
    print "  Version Name: '#{version.version_name}'"
    print "  Module: #{mod and mod.name or 'unknown'} (id: #{version.module_id})"
    print "  User: #{user and user.username or 'unknown'}"
    print "  URL: https://luarocks.org/modules/#{user and user.username or '?'}/#{mod and mod.name or '?'}/#{version.version_name}"
    print ""

print "Total versions with invalid names: #{bad_versions}"
print ""

-- Check rocks
print "=== ROCKS WITH INVALID ARCH ==="
bad_rocks = 0
for rock in *Rocks\select!
  unless is_valid_manifest_string rock.arch
    bad_rocks += 1
    version = rock\get_version!
    mod = version and version\get_module!
    user = mod and mod\get_user!
    print "Rock ID: #{rock.id}"
    print "  Arch: '#{rock.arch}'"
    print "  Version: #{version and version.version_name or 'unknown'} (id: #{rock.version_id})"
    print "  Module: #{mod and mod.name or 'unknown'}"
    print "  User: #{user and user.username or 'unknown'}"
    print ""

print "Total rocks with invalid arch: #{bad_rocks}"
print ""

-- Summary
print "=== SUMMARY ==="
print "Modules with invalid names: #{bad_modules}"
print "Versions with invalid names: #{bad_versions}"
print "Rocks with invalid arch: #{bad_rocks}"
print "Total issues: #{bad_modules + bad_versions + bad_rocks}"
