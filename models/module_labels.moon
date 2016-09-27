db = require "lapis.db"
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"
import safe_insert from require "helpers.models"

class ModuleLabels extends Model
  @timestamp: true

  @relations: {
    {"label", belongs_to: "Labels"}
    {"module", belongs_to: "Modules"}
  }

  @primary_key: {"label_id", "module_id"}

  @create: safe_insert

  @remove: (label, module) =>
    assert module.id and label.id, "Missing module/label"

    db.delete @@table_name!, {
      label_id: label.id
      module_id: module.id
    }
