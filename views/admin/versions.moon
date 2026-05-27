import enum from require "lapis.db.model"

class AdminVersions extends require "widgets.admin.page"
  @needs: {"versions", "pager"}

  inner_content: =>
    @filter_form (field) ->
      field "module_id"
      field "lua_version"
      field "development", type: "bool"
      field "archived", type: "bool"
      field "sort", enum {
        "downloads"
        "rockspec_downloads"
        "created_at"
      }

    @render_pager @pager
    @column_table @versions, {
      "id"
      {"version_name", value: (v) -> v}
      {":get_module", label: "module"}
      "lua_version"
      {"development", type: "boolean"}
      {"archived", type: "boolean"}
      "downloads"
      "rockspec_downloads"
      "revision"
      "created_at"
    }
    @render_pager @pager
