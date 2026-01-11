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
      when "Rocks"
        a href: @url_for(instance), ->
          code instance.rock_fname
      else
        em "<don't know how to render model (#{instance.__class.__name})>"

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

