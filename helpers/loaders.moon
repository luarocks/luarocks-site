
import Users, Modules, Versions from require "models"

import
  assert_error
  from require "lapis.application"

load_module = =>
  @user = assert_error Users\find(slug: @params.user), "Invalid user"
  @module = assert_error Modules\find(user_id: @user.id, name: @params.module\lower!), "Invalid module"
  @module.user = @user

  if @params.version
    @version = assert_error Versions\find({
      module_id: @module.id
      version_name: @params.version\lower!
    }), "Invalid version"

  if @route_name and (@module.name != @params.module or @version and @version.version_name != @params.version)
    url = @url_for @route_name, user: @user, module: @module, version: @version
    @write status: 301, redirect_to: url
    return false

  true

load_manifest = (key="id") =>
  @manifest = assert_error Manifests\find([key]: @params.manifest), "Invalid manifest id"

{ :load_module, :load_manifest }
