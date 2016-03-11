
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"
import safe_insert from require "helpers.models"

class LabelsModules extends Model
  @timestamp: true

  @relations: {
  	{"label", belongs_to: "Labels"}
  	{"module", belongs_to: "Modules"}
	}

  @create: (opts={}) =>

		f = safe_insert @, opts
		true


