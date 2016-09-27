import encode_query_string, parse_query_string from require "lapis.util"

db = require "lapis.db"

import
  modules
  labels
  users
  from require "secrets.toolbox"

import
  Modules
  ModuleLabels
  LabelsModules
  Followings
  from require "models"


_labels = {l.id,l.name for l in *labels}
_modules = {m.id,m.name for m in *modules}

class Toolbox
  create_labels_from_dump: =>
    for l in *labels
      ModuleLabels\create name: l.name

  apply_labels_to_modules: =>
    for m in *modules
      mod = Modules\find name: m.name
      if mod 
        for l in *m.labels
          label = ModuleLabels\find name: _labels[tonumber l]
          if label 
            LabelsModules\create module_id: mod.id, label_id: label.id

  transfer_endorsements: =>
    transfer_count = 0
    endorsements = {}

    for u in *users
      if u.email == @current_user.email
        endorsements = u.endorsements

    for e in *endorsements
        name = _modules[tonumber e]
        if name
          m = Modules\find name: name
          if m
            follow = Followings\find source_user_id: @current_user.id, object_id: m.id
            if not follow
              Followings\create {
                source_user_id: @current_user.id
                object_type: Followings.object_types.module
                object_id: m.id
              }
              transfer_count += 1

    return transfer_count
