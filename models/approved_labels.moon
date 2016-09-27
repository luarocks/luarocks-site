
import Model from require "lapis.db.model"
import slugify from require "lapis.util"

class ApprovedLabels extends Model
  @timestamp: true

  @create: (opts) =>
    opts.name = slugify opts.name
    assert opts.name != ""
    super opts
