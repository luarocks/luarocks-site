import time_ago_in_words from require "lapis.util"

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

  _format_table_value: (object, field) =>
    local enum, custom_val, label
    opts = {}

    if type(field) == "table"
      label = field.label
      {field, enum} = field

    if type(enum) == "function"
      func = enum
      custom_val = -> func object
      enum = nil

    local style
    val = if method = field\match "^:(.+)$"
      object[method] object
    else
      object[field]

    if enum
      val = "#{enum[val]} (#{val})"

    switch type(val)
      when "boolean"
        opts.style = "color: #{val and "green" or "red"}"
      when "number"
        val = @format_number val
      when "nil"
        unless custom_val
          opts.style = "color: gray; font-style: italic"

    if val and (field\match("_at$") or field\match("_date_utc$"))
      opts.title = val
      custom_val = -> @render_date val

    if val and field == "ip"
      custom_val = ->
        a href: @url_for("admin_ip_address", nil, ip: val), val

    label or field, custom_val or tostring(val), opts


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
    assert fields, "missing fields"

    element "table", class: "table", ->
      thead ->
        tr ->
          for field in *fields
            local label
            if type(field) == "table"
              label = field.label
              {field, enum} = field

            td label or field

      for object in *objects
        tr ->
          for field in *fields
            _, val, opts = @_format_table_value object, field
            td opts, val
