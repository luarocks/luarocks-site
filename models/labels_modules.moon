db = require "lapis.db"
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"
import safe_insert from require "helpers.models"

class LabelsModules extends Model
  @timestamp: true

  @relations: {
    {"label", belongs_to: "ModuleLabels"}
    {"module", belongs_to: "Modules"}
  }

  @primary_key: {"label_id", "module_id"}

  @create: (opts={}) =>
    f = safe_insert @, opts
    true

  @remove: (label, module) =>
    assert module.id and label.id, "Missing module/label"

    res = db.delete @@table_name!, {
      label_id: label.id
      module_id: module.id
    }
    res
