import enum from require "lapis.db.model"
import FileAudits from require "models"

class AdminAudits extends require "widgets.admin.page"
  @needs: {"audits", "pager"}

  inner_content: =>
    p ->
      text "Audits are run on GitHub runners under the "
      a href: "https://github.com/luarocks/rocks-audit/actions", "luarocks/rocks-audit"
      text " repository."

    @filter_form (field) ->
      field "status", enum {
        "pending"
        "dispatched"
        "running"
        "completed"
        "failed"
      }
      field "object_type", enum {
        "version"
        "rock"
      }

    @render_pager @pager

    div class: "audits_table", ->
      @column_table @audits, {
        {"id", (audit) ->
          a href: @url_for("admin.audit", id: audit.id), audit.id
        }
        {"module", value: (audit) ->
          if object = audit\get_object!
            switch audit.object_type
              when FileAudits.object_types.version
                object\get_module!
              when FileAudits.object_types.rock
                if v = object\get_version!
                  v\get_module!
        }
        {"file", (audit) ->
          span class: "audit_type", FileAudits.object_types\to_name audit.object_type
          if object = audit\get_object!
            @render_model object
        }
        {"status", (audit) ->
          status = FileAudits.statuses\to_name audit.status
          span class: "audit_status status_#{status}", status

          switch audit.status
            when FileAudits.statuses.failed
              if audit.error_message
                div class: "audit_error", audit.error_message
            when FileAudits.statuses.completed
              result = audit\get_result!
              div class: "audit_summary", ->
                if result and type(result.verdict) == "string"
                  span class: "audit_verdict verdict_#{result.verdict\gsub "[^%w_]", ""}", result.verdict
                  text " "

                if audit\is_likely_spam!
                  span class: "audit_verdict verdict_spam", "spam"
                  text " "

                if result and type(result.summary) == "table"
                  total = tonumber(result.summary.total_findings) or 0
                  text "#{total} finding#{total == 1 and "" or "s"} · "

                a href: @url_for("admin.audit", id: audit.id), "details"
        }
        {"run", (audit) ->
          if audit.external_id
            a href: "https://github.com/luarocks/rocks-audit/actions/runs/#{audit.external_id}", audit.external_id
        }
        {"duration", (audit) ->
          -- started_at is set by the runner's started callback, so this
          -- excludes time spent queued on GitHub
          times = {}
          table.insert times, "started #{audit.started_at} UTC" if audit.started_at
          table.insert times, "finished #{audit.finished_at} UTC" if audit.finished_at
          title = table.concat times, "\n"

          text, running = audit\duration_text!
          if running
            span class: "audit_duration running", :title, "#{text} so far"
          elseif text
            span class: "audit_duration", :title, text
        }
        "created_at"
        {"actions", (audit) ->
          switch audit.status
            when FileAudits.statuses.pending
              form action: @url_for("admin.audit_dispatch", id: audit.id), method: "POST", ->
                @csrf_input!
                button type: "submit", "Dispatch"
            when FileAudits.statuses.failed, FileAudits.statuses.completed
              -- finished audits are kept as they are, running again queues a new audit
              form action: @url_for("admin.audit_create"), method: "POST", ->
                input type: "hidden", name: "object_type", value: FileAudits.object_types\to_name audit.object_type
                input type: "hidden", name: "object_id", value: audit.object_id
                @csrf_input!
                button type: "submit", "Run again"
        }
      }

    @render_pager @pager
