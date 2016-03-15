import encode_query_string, parse_query_string from require "lapis.util"

db = require "lapis.db"

import
  modules
  labels
  from require "secrets.toolbox"

import
  Modules
  Labels
  LabelsModules
  from require "models"


_labels = {}
for l in *labels
	_labels[l.id] = l.name

_modules = {}
for m in *modules
	_modules[m.id] = m.name

class Toolbox

	create_labels_from_dump: =>
		for l in *labels
			Labels\create name: l.name

	apply_labels_to_modules: =>
		for m in *modules
			mod = Modules\find name: m.name
			if mod 
				for l in *(m.labels)
					label = Labels\find name: _labels[tonumber l]
					if label 
						LabelsModules\create module_id: mod.id, label_id: label.id








