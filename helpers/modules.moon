
import assert_valid from require "lapis.validate"
import assert_page from require "helpers.app"

import Users, Modules from require "models"

paginated_modules = (object_or_pager, opts={}) =>
  assert_page @

  if type(opts) == "function"
    opts = { prepare_results: opts }

  opts.prepare_results or= (mods) ->
    Modules\preload_relation mods, "user", fields: "id, slug, username"
    Users\include_in mods, "user_id", fields: "id, slug, username"
    mods

  @pager = if object_or_pager.get_page
    -- it's already a pager, hijack it
    object_or_pager.opts or= {}
    object_or_pager.opts.prepare_results = opts.prepare_results

    object_or_pager
  else
    opts.per_page or= 50
    opts.fields or= "id, name, display_name, user_id, downloads, summary"
    object_or_pager\find_modules opts

  @modules = @pager\get_page @page

  if @page > 1 and not next @modules
    return redirect_to: @req.parsed_url.path

  if @page > 1 and @title
    @title ..= " - Page #{@page}"

  @modules

{ :paginated_modules }
