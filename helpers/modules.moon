
import assert_valid from require "lapis.validate"

import Users from require "models"

paginated_modules = (object_or_pager, opts={}) =>
  assert_valid @params, {
    {"page", optional: true, is_integer: true}
  }

  if type(opts) == "function"
    opts = { prepare_results: opts }

  opts.prepare_results or= (mods) ->
    Users\include_in mods, "user_id", fields: "id, slug, username"
    mods

  @page = tonumber(@params.page) or 1

  @pager = if object_or_pager.get_page
    -- it's already a pager, hijack it
    object_or_pager.prepare_results = opts.prepare_results
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
