PageHeader = require "widgets.page_header"

types = require "lapis.validate.types"
import instance_of from  require "tableshape.moonscript"

import Enum from require "lapis.db.model"

is_enum = instance_of Enum

not_empty = -types.empty


-- base class for all admin pages
class AdminPage extends require "widgets.page"
  render_nav_tab: (name, label, href) =>
    href or= @url_for name
    a href: href, class: "tab #{name == @route_name and "active" or ""}", label

  header_content: =>
    widget PageHeader {
      inner_content: ->
        div class: "page_header_inner" , ->
          h1 ->
            if @title
              text @title
              text " — "

            text "Admin"

        div class: "page_tabs", ->
          @render_nav_tab "admin.users", "Users"
          @render_nav_tab "admin.modules", "Modules"
          @render_nav_tab "admin.versions", "Versions"
          @render_nav_tab "admin.rocks", "Rocks"
          @render_nav_tab "admin.labels", "Labels"
          @render_nav_tab "admin.audits", "Audits"
          @render_nav_tab "admin.cache", "Cache"
          @render_nav_tab "admin.db_tables", "DB Tables"
    }


  render_model: (instance) =>
    switch instance.__class.__name
      when "Users"
        a href: @url_for(instance), instance\name_for_display!
        text " ("
        a href: @url_for("admin.user", id: instance.id), "admin"
        text ")"
      when "Manifests"
        a href: @url_for(instance), instance\name_for_display!
      when "Modules"
        a href: @url_for(instance), instance\name_for_display!
        text " ("
        a href: @url_for("admin.module", id: instance.id), "admin"
        text ")"
      when "Versions"
        a href: @url_for(instance), ->
          code instance\name_for_display!
        text " ("
        a href: @url_for("admin.version", id: instance.id), "admin"
        text ")"
      when "Rocks"
        a href: @url_for(instance), ->
          code instance.rock_fname
        text " ("
        a href: @url_for("admin.rock", id: instance.id), "admin"
        text ")"
      else
        em "<don't know how to render model (#{instance.__class.__name})>"

  -- verdict (or status, if there's no result yet) of a file audit, linked to
  -- its page
  render_audit_label: (audit) =>
    import FileAudits from require "models"

    a href: @url_for("admin.audit", id: audit.id), ->
      result = audit\get_result!
      if result and type(result.verdict) == "string"
        span class: "audit_verdict verdict_#{result.verdict\gsub "[^%w_]", ""}", result.verdict
      else
        status = FileAudits.statuses\to_name audit.status
        span class: "audit_status status_#{status}", status

    if audit\is_likely_spam!
      text " "
      span class: "audit_verdict verdict_spam", "spam"

  -- latest audit of a version's rockspec or a rock, with a count of older ones
  render_latest_audit: (object) =>
    audits = object\get_audits!
    if audit = audits[1]
      @render_audit_label audit
      if #audits > 1
        span class: "audit_count", " +#{#audits - 1} older"

  render_short_hash: (value) =>
    if value
      span class: "hash", title: value, value\sub(1, 10) .. "…"

  render_rocks_table: (rocks) =>
    @column_table rocks, {
      {"rock id", (rock) -> a href: @url_for("admin.rock", id: rock.id), rock.id}
      {"arch", (rock) -> text rock.arch}
      {"file", (rock) -> a href: @url_for(rock), rock.rock_fname}
      {"downloads", (rock) -> text @format_number rock.downloads}
      {"created", (rock) -> @render_date rock.created_at}
      {"sha256", (rock) -> @render_short_hash rock.sha256}
      {"md5", (rock) -> @render_short_hash rock.md5}
      {"latest audit", (rock) -> @render_latest_audit rock}
      {"", (rock) -> @render_audit_button "rock", rock}
    }

  -- queues a new audit of a version's rockspec or a rock
  render_audit_button: (object_type, object) =>
    form action: @url_for("admin.audit_create"), method: "POST", ->
      input type: "hidden", name: "object_type", value: object_type
      input type: "hidden", name: "object_id", value: object.id
      @csrf_input!
      button type: "submit", "Audit"

  render_audits_table: (audits) =>
    import FileAudits from require "models"

    unless next audits
      p class: "empty_table", "No audits"
      return

    @column_table audits, {
      {"id", (audit) -> a href: @url_for("admin.audit", id: audit.id), audit.id}
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
      {"result", (audit) ->
        if audit.status == FileAudits.statuses.completed
          @render_audit_label audit
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
    }

  format_table_value_by_type: (value_type, field, value, field_name) =>
    switch value_type
      when "model"
        -> @render_model value
      else
        super value_type, field, value, field_name

  filter_form: (fn) =>
    field_names = {}

    render_field = (name, opts={}, more_opts) ->
      table.insert field_names, name

      if is_enum opts
        enum = opts
        opts = more_opts or {}
        fieldset class: "enum_field", ->
          legend name

          have_value = not_empty @params[name]

          input type: "hidden", name: name, value: have_value and @params[name] or nil
          onclick = "event.target.closest('.enum_field').querySelector('input[type=hidden]').value = event.target.value"

          ul ->
            for val in *enum
              li ->
                button {
                  value: val
                  :onclick
                  class: {
                    active: have_value and val == @params[name]
                  }
                }, val

            if have_value
              li ->
                button {
                  name: name
                  value: ""
                  :onclick
                }, -> em "Clear"

        return

      switch opts.type
        when "bool", "boolean"
          label ->
            input {
              type: "checkbox"
              name: name
              checked: not_empty @params[name]
              onchange: "this.form.submit()"
              class: "filter_field"
            }
            text " "
            text name
        else
          local list_id
          if opts.choices
            list_id = "choices_#{name}"
            datalist id: list_id, ->
              for val in *opts.choices
                option value: val, val

          input {
            type: opts.type or "text"
            value: @params[name]
            name: name
            title: name
            class: "filter_field"
            placeholder: opts.placeholder or name
            list: list_id
          }

    has_filter = ->
      for name in *field_names
        return true if not_empty @params[name]

      false

    form {
      class: "filter_form form"
    }, ->
      button type: "submit", style: "display: none;"
      fn render_field
      if has_filter!
        a href: "?", class: "button", "Clear"

