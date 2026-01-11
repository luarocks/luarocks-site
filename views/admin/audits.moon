import enum from require "lapis.db.model"
import FileAudits from require "models"

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

    @column_table @audits, {
      "id"
      {"object_type", FileAudits.object_types}
      {"module", value: (audit) ->
        if object = audit\get_object!
          switch audit.object_type
            when FileAudits.object_types.version
              object\get_module!
            when FileAudits.object_types.rock
              if v = object\get_version!
                v\get_module!
      }
      {"object", value: (audit) -> audit\get_object! }
      {"status", FileAudits.statuses}
      {"external_id", (audit) ->
        if audit.external_id
          a href: "https://github.com/luarocks/rocks-audit/actions/runs/#{audit.external_id}", audit.external_id
      }
      "created_at"
      {"actions", (audit) ->
        switch audit.status
          when FileAudits.statuses.pending
            form {
              action: @url_for "admin.audit_dispatch", id: audit.id
              method: "POST"
              class: "dispatch_form"
            }, ->
              @csrf_input!
              button type: "submit", class: "button", "Dispatch"
          when FileAudits.statuses.completed
            if audit.result_data
              button {
                class: "button"
                onclick: "this.nextElementSibling.style.display = this.nextElementSibling.style.display === 'none' ? 'block' : 'none'"
              }, "Results"
              pre style: "display: none; max-width: 400px; overflow: auto;", audit.result_data
      }
    }

    @render_pager @pager

