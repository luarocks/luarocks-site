lapis = require "lapis"
db = require "lapis.db"

import
  assert_csrf
  assert_editable
  require_login
  capture_errors_404
  from require "helpers.app"

import paginated_modules from require "helpers.modules"
import assert_valid, with_params from require "lapis.validate"

import load_module from require "helpers.loaders"

types = require "lapis.validate.types"

import
  capture_errors
  respond_to
  assert_error
  from require "lapis.application"

class MoonRocksLabels extends lapis.Application
  [label: "/labels/:label"]: capture_errors_404 with_params {
    {"label", types.limited_text 256}
    {"non_root", types.empty / false + types.any / true}
  }, (params) =>
    import Manifests, ApprovedLabels, Modules from require "models"

    @show_non_root = params.non_root

    @approved_label = ApprovedLabels\find name: params.label

    @title = if @show_non_root
      "All modules labeled '#{params.label}'"
    else
      "Modules labeled '#{params.label}'"

    clause = {
      db.interpolate_query "? && labels", db.array { params.label }
      "labels is not null"
    }

    unless @show_non_root
      manifests = { Manifests\root!.id }
      table.insert clause,
        db.interpolate_query "exists(
          select 1 from manifest_modules where module_id = modules.id and manifest_id in ?
        )", db.list manifests

    pager = Modules\paginated "where #{table.concat clause, " and "}", {
      per_page: 50
      fields: "id, name, display_name, user_id, downloads, summary"
    }

    paginated_modules @, pager
    status = unless next @modules then 404
    render: true, :status

