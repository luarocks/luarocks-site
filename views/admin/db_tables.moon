import enum from require "lapis.db.model"

class AdminDbTables extends require "widgets.admin.page"
  inner_content: =>
    @filter_form (field) ->
      field "filter"

      field "sort", enum {
        -- "total_size" -- this is the default
        "indexes_size"
      }

    @column_table @tables, {
      {"table_name", (t) ->
        code t.table_name
      }
      "table_size"
      "indexes_size"
      "total_size"
    }
