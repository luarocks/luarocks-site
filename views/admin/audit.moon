import FileAudits from require "models"

-- result_data comes from the runner: any field can be missing, the wrong
-- type, or a JSON null (cjson.null userdata), so only accept these
str = (v) ->
  switch type(v)
    when "string" then v
    when "number" then tostring v

list = (v) -> type(v) == "table" and v or {}

class AdminAudit extends require "widgets.admin.page"
  @needs: {"audit"}

  inner_content: =>
    p -> a href: @url_for("admin.audits"), "← All audits"

    @field_table @audit, {
      {"file", (audit) ->
        span class: "audit_type", FileAudits.object_types\to_name audit.object_type
        if object = audit\get_object!
          @render_model object
      }
      {"status", (audit) ->
        status = FileAudits.statuses\to_name audit.status
        span class: "audit_status status_#{status}", status
        if audit.error_message
          div class: "audit_error", audit.error_message
      }
      {"run", (audit) ->
        if audit.external_id
          a href: "https://github.com/luarocks/rocks-audit/actions/runs/#{audit.external_id}", audit.external_id
      }
      {"duration", (audit) ->
        duration, running = audit\duration_text!
        text running and "#{duration} so far" or duration
      }
      "created_at"
      "started_at"
      "finished_at"
    }

    result = @audit\get_result!
    return unless result

    h2 "Result"
    @field_table result, {
      {"verdict", (r) ->
        if verdict = str r.verdict
          span class: "audit_verdict verdict_#{verdict\gsub "[^%w_]", ""}", verdict

        if @audit\is_likely_spam!
          text " "
          span class: "audit_verdict verdict_spam", "spam"
      }
      {"findings", (r) ->
        s = list r.summary
        text "#{tonumber(s.high_severity) or 0} high, #{tonumber(s.medium_severity) or 0} medium, #{tonumber(s.low_severity) or 0} low"
      }
      {"scanner", (r) ->
        s = list r.scanner
        text table.concat [x for x in *{str(s.name) or "?", str(s.version), str(s.model) and "(#{s.model})"} when x], " "
      }
      {"agent", (r) ->
        text list(r.usage).agent_skipped == true and "skipped (cleared by screening)" or "ran"
      }
    }

    findings = {}
    for key in *{"findings", "static_findings", "extraction_findings"}
      for f in *list result[key]
        table.insert findings, f if type(f) == "table"

    h2 "Findings"
    if next findings
      for f in *findings
        severity = (str(f.severity) or "?")\gsub "[^%w]", ""
        div class: "audit_finding", ->
          div class: "finding_header", ->
            span class: "audit_severity severity_#{severity}", severity
            strong str(f.title) or "(untitled)"
            span class: "finding_meta", table.concat [x for x in *{str(f.category), str(f.trigger)} when x], " · "

          if path = str f.file
            code class: "finding_location", f.line and "#{path}:#{str(f.line) or "?"}" or path

          if desc = str f.description
            p desc

          if why = str f.malware_rationale
            p ->
              strong "Why: "
              text why

          if snippet = str f.code_snippet
            pre snippet
    else
      p class: "empty_table", "No findings"

    screened = [f for f in *list list(result.screening).files when type(f) == "table"]
    if next screened
      h2 "Screening"
      @column_table screened, {
        {"file", (f) -> code str(f.path) or "?"}
        {"tier", (f) -> text str(f.tier) or ""}
        {"risk", (f) -> text str(f.risk) or ""}
      }

    snippets = [s for s in *list list(result.triage).hot_snippets when type(s) == "table"]
    if next snippets
      h2 "Hints"
      p class: "sub", "Lines matched by the scanner's patterns. These are signals for triage, not findings."
      @column_table snippets, {
        {"label", (s) -> text str(s.label) or ""}
        {"location", (s) -> code "#{str(s.path) or "?"}:#{str(s.line) or "?"}"}
        {"text", (s) -> code class: "hint_text", (str(s.text) or "")\match "^%s*(.-)%s*$"}
      }

    spam = list result.spam
    if next spam
      h2 "Spam signals"
      @field_table spam, {
        {"likely spam", (s) -> text s.likely == true and "yes" or "no"}
        {"signals", (s) -> text table.concat [x for x in *list s.signals when type(x) == "string"], ", "}
        {"homepage", (s) -> text str(s.homepage) or ""}
        {"scores", (s) ->
          scores = ["#{k} #{str s[k]}" for k in *{"promotional", "functional", "link_helpers"} when str s[k]]
          text table.concat scores, ", "
        }
      }

    rockspecs = [r for r in *list list(list(result.triage).project).rockspecs when type(r) == "table"]
    for rockspec in *rockspecs
      h2 "Rockspec"
      @field_table rockspec, {
        {"package", (r) -> text "#{str(r.package) or "?"} #{str(r.version) or ""}"}
        {"build type", (r) -> text str(r.build_type) or ""}
        {"source", (r) ->
          code str(r.source_url) or ""
          if tag = str r.source_tag
            text " (tag #{tag})"
        }
        {"homepage", (r) -> text str(r.homepage) or ""}
        {"dependencies", (r) -> text table.concat [x for x in *list r.dependencies when type(x) == "string"], ", "}
      }

    h2 "Raw result"
    div assert @format_table_value_by_type "json", {}, result, "result_data"
