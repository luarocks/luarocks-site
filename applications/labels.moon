lapis = require "lapis"
db = require "lapis.db"

import capture_errors_404 from require "helpers.app"
import paginated_modules from require "helpers.modules"
import trim_filter from require "lapis.util"
import assert_valid from require "lapis.validate"

class MoonRocksLabels extends lapis.Application
  [label: "/labels/:label"]: capture_errors_404 =>
    import ApprovedLabels, Modules from require "models"

    trim_filter @params
    assert_valid @params, {
      {"label", type: "string", exists: true}
    }

    @approved_label = ApprovedLabels\find name: @params.label

    @title = "Modules labeled '#{@params.label}'"

    pager = Modules\paginated "
      where ? && labels and labels is not null
    ", db.array {
      @params.label
    }

    paginated_modules @, pager, {
      per_page: 50
      fields: "id, name, display_name, user_id, downloads, summary"
    }

    status = unless next @modules then 404
    render: true, :status
