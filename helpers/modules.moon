
import assert_valid from require "lapis.validate"
import assert_page from require "helpers.app"

import Users, Modules, Versions from require "models"

db = require "lapis.db"

-- current_version can point to an archived or deleted version, so listings
-- show the newest non-archived version instead
preload_latest_versions = (mods) ->
  return mods unless next mods

  versions = Versions\select "
    where module_id in ? and not archived
    order by module_id, created_at desc
  ", db.list([mod.id for mod in *mods]), {
    fields: "distinct on (module_id) id, module_id, created_at"
  }

  by_module_id = {v.module_id, v for v in *versions}
  for mod in *mods
    mod.latest_version = by_module_id[mod.id]

  mods

paginated_modules = (object_or_pager, opts={}) =>
  assert_page @

  if type(opts) == "function"
    opts = { prepare_results: opts }

  opts.prepare_results or= (mods) ->
    Modules\preload_relation mods, "user", fields: "id, slug, username"
    Users\include_in mods, "user_id", fields: "id, slug, username"
    preload_latest_versions mods
    mods

  @pager = if object_or_pager.get_page
    -- it's already a pager, hijack it
    object_or_pager.opts or= {}
    object_or_pager.opts.prepare_results = opts.prepare_results

    object_or_pager
  else
    opts.per_page or= 50
    opts.fields or= "id, name, display_name, user_id, downloads, summary, created_at"
    object_or_pager\find_modules opts

  @modules = @pager\get_page @page

  if @page > 1 and not next @modules
    return redirect_to: @req.parsed_url.path

  if @page > 1 and @title
    @title ..= " - Page #{@page}"

  @modules

{ :paginated_modules, :preload_latest_versions }
