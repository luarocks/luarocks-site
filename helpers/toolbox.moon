import
  Modules
  ApprovedLabels
  Followings
  from require "models"

class ToolboxImport
  new: (@modules, @labels, @users)=>
    import modules, labels, users from require "secret.toolbox"

    @modules or= modules
    @labels or= labels
    @users or= users

    @labels_by_id = {l.id, l.name for l in *@labels}
    @modules_by_id = {m.id, m.name for m in *@modules}

  create_approved_labels: =>
    for l in *@labels
      ApprovedLabels\create name: l.name

  apply_labels_to_modules: =>
    for m in *@modules
      for mod in *Modules\select "where name = ?", m.name
        mod\set_labels [@labels_by_id[tonumber l] for l in *m.labels]

  transfer_endorsements: =>
    error "not yet"
    transfer_count = 0
    endorsements = {}

    for u in *@users
      if u.email == @current_user.email
        endorsements = u.endorsements

    for e in *endorsements
      name = @modules_by_id[tonumber e]
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


{:ToolboxImport}
