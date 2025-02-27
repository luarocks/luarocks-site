
uri = ngx.var.request_uri

-- manifests are served by the app
return ngx.exec "/" if uri\match "/manifest[^/]*/?$"

import Users, Modules, Versions, Rocks, Manifests from require "models"

types = require "lapis.validate.types"

assert = (thing) ->
  ngx.exit 404 unless thing
  thing

should_increment = ->
  if agent = ngx.var.http_user_agent
    agent = agent\lower!
    if agent\match"luarocks" or agent\match"luasocket" or agent\match"wget" or agent\match"curl"
      true

is_rockspec = ->
  (uri\match "%.rockspec$")

validate_text = types.limited_text 512

-- the user specific manifestg
object = if uri\match "^/manifests"
  slug = assert validate_text\transform ngx.var.username
  file = assert validate_text\transform ngx.var.filename
  user = assert Users\find(:slug)

  if is_rockspec!
    unpack Versions\select [[
      INNER JOIN modules
        ON (modules.id = module_id and modules.user_id = ?)
      WHERE rockspec_fname = ?
    ]], user.id, file
  else
    unpack Rocks\select [[
      INNER JOIN versions
        ON (versions.id = version_id)
      INNER JOIN modules
        ON (modules.id = versions.module_id and modules.user_id = ?)
      WHERE rock_fname = ?
    ]], user.id, file

else
  file_name = assert validate_text\transform ngx.var.filename
  manifest = if uri\match "^/m/"
    manifest_name = assert validate_text\transform ngx.var.manifest_name
    assert Manifests\find name: manifest_name
  else
    Manifests\root!

  -- TODO: this query is pretty nasty to do on every file request
  if is_rockspec!
    unpack Versions\select [[
      INNER JOIN manifest_modules
        ON (manifest_modules.module_id = versions.module_id and manifest_modules.manifest_id = ?)
      WHERE rockspec_fname = ?
    ]], manifest.id, file_name
  else
    unpack Rocks\select [[
      INNER JOIN versions
        ON (versions.id = rocks.version_id)
      INNER JOIN manifest_modules
        ON (manifest_modules.module_id = versions.module_id and manifest_modules.manifest_id = ?)
      WHERE rock_fname = ?
    ]], manifest.id, file_name

assert object

if object.increment_download and should_increment!
  object\increment_download!

url, untrusted = object\url!

if untrusted
  -- trailing slash required for domain urls
  unless url\match "//.-/"
    url ..= "/"

  assert object.content_type, "external url must provide content type"

if object.content_type
  ngx.header.content_type = object\content_type!

ngx.header["x-object_url"] = url
ngx.var._url = url

