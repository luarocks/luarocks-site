import
  Modules
  ApprovedLabels
  Followings
  from require "models"

db = require "lapis.db"

class ToolboxImport
  new: (@modules, @labels, @users)=>
    import modules, labels, users from require "secret.toolbox"

    @modules or= modules
    @labels or= labels
    @users or= users

    @labels_by_id = {l.id, l.name for l in *@labels}
    @modules_by_id = {m.id, m.name for m in *@modules}
    @users_by_email = {user.email, user for user in *@users}

  create_approved_labels: =>
    for l in *@labels
      ApprovedLabels\create name: l.name

  apply_labels_to_modules: =>
    for m in *@modules
      labels = [@labels_by_id[tonumber l] for l in *m.labels]
      continue unless next labels

      found = Modules\select "where name = ?", m.name

      unless next found
        url = m.url and m.url\gsub "^%w+", ""
        url = nil if url == ""
        if url
          found = Modules\select "where homepage like '%' || ?", url

      for mod in *found
        mod\set_labels labels

  modules_endorsed_by_user: (user) =>
    email = user.email
    toolbox_user = @users_by_email[email]
    return nil, "no toolbox account" unless toolbox_user
    unless toolbox_user.endorsements and next toolbox_user.endorsements
      return nil, "no endorsements"

    module_names = [@modules_by_id[tonumber id] for id in *toolbox_user.endorsements]
    modules = Modules\select "where name in ?", db.list module_names
    by_name = {}

    for m in *modules
      by_name[m.name] or= {}
      table.insert by_name[m.name], m

    out = for _, modules in pairs by_name
      if #modules > 1
        in_root = nil
        for m in *modules
          if m\in_root_manifest!
            in_root = m
            break

        if in_root
          in_root
        else
          table.sort modules, (a, b) -> a.downloads > b.downloads
          modules[1]
      else
        modules[1]

    out

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
