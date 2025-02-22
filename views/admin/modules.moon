import enum from require "lapis.db.model"

class AdminModules extends require "widgets.admin.page"
  @needs: {"users", "pager"}

  inner_content: =>
    @filter_form (field) ->
      field "label"
      field "sort", enum {
        "downloads",
        "followers_count",
        "stars_count"
        "versions_count"
      }

    @render_pager @pager
    @column_table @modules, {
      "id"
      {"name", value: (m) -> m}
      {":get_user", label: "user"}
      "downloads"
      "followers_count"
      {":get_current_version", label: "current_version"}
      "created_at"
      "updated_at"
      {"labels", type: "json"}
      {"summary", type: "collapse_pre", truncate: 60}
    }
    @render_pager @pager


