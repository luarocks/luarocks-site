import enum from require "lapis.db.model"

class AdminRocks extends require "widgets.admin.page"
  @needs: {"rocks", "pager"}

  inner_content: =>
    @filter_form (field) ->
      field "version_id"
      field "arch"
      field "sort", enum {
        "downloads"
        "revision"
      }

    @render_pager @pager
    @column_table @rocks, {
      "id"
      {"rock_fname", value: (r) -> r}
      "arch"
      {":get_version", label: "version"}
      {"module", value: (r) -> r\get_version!\get_module!}
      "downloads"
      "revision"
      "created_at"
    }
    @render_pager @pager
