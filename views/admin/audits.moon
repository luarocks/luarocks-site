import enum from require "lapis.db.model"

class AdminAudits extends require "widgets.admin.page"
  @needs: {"audits", "pager"}

  inner_content: =>
    @filter_form (field) ->
      field "status", enum {
        "pending"
        "running"
        "completed"
        "failed"
      }
      field "object_type", enum {
        "version"
        "rock"
      }

    @render_pager @pager

    element "table", class: "nice_table", ->
      thead ->
        tr ->
          th "ID"
          th "Type"
          th "Object"
          th "Status"
          th "External ID"
          th "Created"
          th "Actions"

      tbody ->
        for audit in *@audits
          tr ->
            td audit.id
            td audit\get_object_type!
            td ->
              obj = audit\get_object!
              if obj
                switch audit\get_object_type!
                  when "version"
                    mod = obj\get_module!
                    if mod
                      a href: @url_for(obj), "#{mod.name} #{obj.version_name}"
                    else
                      code obj.rockspec_fname
                  when "rock"
                    version = obj\get_version!
                    if version
                      mod = version\get_module!
                      a href: @url_for(obj), "#{mod and mod.name or '?'} #{obj.rock_fname}"
                    else
                      code obj.rock_fname
              else
                em "deleted"

            td ->
              span class: "status_#{audit\get_status!}", audit\get_status!

            td ->
              if audit.external_id
                code tostring audit.external_id
              else
                em "—"

            td audit.created_at

            td ->
              if audit\get_status! == "pending"
                form {
                  action: @url_for "admin.audit_dispatch", id: audit.id
                  method: "POST"
                  class: "dispatch_form"
                }, ->
                  @csrf_input!
                  button type: "submit", class: "button", "Dispatch"

              if audit\get_status! == "completed" and audit.result_data
                button {
                  class: "button"
                  onclick: "this.nextElementSibling.style.display = this.nextElementSibling.style.display === 'none' ? 'block' : 'none'"
                }, "Results"
                pre style: "display: none; max-width: 400px; overflow: auto;", audit.result_data

    @render_pager @pager

