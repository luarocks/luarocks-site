
import Users, Modules, Versions, Manifests, Rocks from require "models"

import assert_error from require "lapis.application"
import assert_valid, with_params from require "lapis.validate"

types = require "lapis.validate.types"

load_module = with_params {
  {"user", types.limited_text 256}
  {"module", types.limited_text 256}
  {"version", types.nil + types.limited_text 256}
  {"arch", types.nil + types.limited_text 256}
}, (params) =>
  @user = assert_error Users\find(slug: params.user), "Invalid user"
  @module = assert_error Modules\find(user_id: @user.id, name: params.module\lower!), "Invalid module"
  @module.user = @user

  if params.version
    @version = assert_error Versions\find({
      module_id: @module.id
      version_name: params.version\lower!
    }), "Invalid version"


  if @version and params.arch
    @rock = assert_error Rocks\find({
      version_id: @version.id
      arch: params.arch
    }), "Invalid rock"


  if @route_name and (@module.name != params.module or @version and @version.version_name != params.version)
    url = @url_for @route_name, user: @user, module: @module, version: @version, arch: @rock
    @write status: 301, redirect_to: url
    return false

  true

load_manifest = (key="id") =>
  @manifest = assert_error Manifests\find([key]: @params.manifest), "Invalid manifest id"

{ :load_module, :load_manifest }
