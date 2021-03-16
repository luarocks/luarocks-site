
import time_ago_in_words from require "lapis.util"

import instance_of from require "tableshape.moonscript"
import Model, Enum from require "lapis.db.model"

instance_of_model = instance_of Model
instance_of_enum = instance_of Enum

_id_gen = 0

class TableHelpers
  _extract_table_fields: (object) =>
    return for k, v in pairs object
      continue if type(v) == "table"
      if cls = object.__class
        plural = (k .. "s")\gsub("ss$", "ses")\gsub "ys$", "ies"
        enum = cls[plural]
        if enum and (enum.__class.__name == "Enum")
          k = {k, enum}
      k

  render_table_value: (object, field) =>
    _, content, opts = @_format_table_value object, field
    if opts
      span opts, content
    else
      text content

  _format_table_value: (object, field) =>
    if type(field) == "string"
      field = {field}

    field_name = field[1]

    if type(field[2]) == "function"
      -- custom renderer
      return field_name, (-> field[2] object)

    value = if method_name = field_name\match "^:(.*)"
      method = object[method_name]
      unless method == nil
        assert type(method) == "function", "expected method for #{field}"
        method object
    elseif type(field.value) == "function"
      field.value object
    else
      object[field_name]

    value_type = if value == nil
      "nil"
    elseif field.type
      field.type
    elseif instance_of_enum field[2]
      "enum"
    elseif field_name\match "_count$"
      "integer"
    elseif field_name\match "_at$"
      "date"
    elseif instance_of_model value
      "model"
    else
      type value

    rendered_value, field_opts = assert @format_table_value_by_type value_type, field, value, field_name
    field_name, rendered_value, field_opts

  -- overridable to allow widgets to customize how they render table values
  -- returns rendered_value, field_opts
  format_table_value_by_type: (value_type, field, value, field_name) =>
    switch value_type
      when "string"
        value
      when "integer", "number"
        if value == 0
          "0", { style: "color: gray" }
        else
          @format_number(value), {
            class: "integer_value"
          }
      when "nil"
        "nil", {
          class: "nil_value"
          style: "font-style: italic; color: gray"
        }
      when "boolean"
        "#{value}", {
          class: "bool_value"
          style: "color: #{value and "green" or "red"}"
        }
      when "date"
        date = require "date"
        @format_relative_timestamp(value), {
          class: "date_value"
          title: date(value)\fmt "${iso}Z"
        }
      when "enum"
        enum = assert field[2], "tried to render field #{field_name} with no enum"
        if enum[value]
          ->
            span {
              title: value
              class: "enum_value"
              "data-name": field_name
              "data-value": enum\to_name(value)
            }, enum\to_name(value)
        else
          -> strong "Invalid enum value: #{value}"
      when "filesize"
        @filesize_format value
      when "checkbox"
        group_name = assert field.input, "missing input name for checkbox"
        form_name = assert field.form, "missing form for checkbox"

        ->
          label style: "margin: -10px; padding: 10px", ->
            input {
              type: "checkbox"
              class: field.class
              name: "#{group_name}[#{value}]"
              value: "on"
              form: form_name
            }

      when "collapse_pre"
        ->
          details ->
            summary ->
              code @truncate value, 180

            pre style: "white-space: pre-wrap;", value

      when "json"
        _id_gen += 1
        _id_gen = _id_gen % 100000
        import to_json from require "lapis.util"

        json_blob = to_json value

        ->
          details ->
            summary ->
              code @truncate json_blob, 120

            pre id: "json-#{_id_gen}"
            script type:"text/javascript", ->
              raw "
                var el = document.getElementById('json-#{_id_gen}')
                el.innerText = JSON.stringify(#{json_blob}, null, 2)
              "
      else
        nil, "Don't know how to render type: #{value_type}"

  field_table: (object, fields, extra_fields) =>
    unless fields
      fields = @_extract_table_fields object

    element "table", class: "table field_table", ->
      for field in *fields
        field, val, opts = @_format_table_value object, field

        tr ->
          td -> strong field
          td opts, val

      extra_fields! if extra_fields

  column_table: (objects, fields) =>
    element "table", class: "table column_table", ->
      thead ->
        tr ->
          for f in *fields
            if type(f) == "table"
              f = f.label or f[1]

            td f

      for object in *objects
        tr ->
          for field in *fields
            field, val, opts = @_format_table_value object, field
            td opts, val

