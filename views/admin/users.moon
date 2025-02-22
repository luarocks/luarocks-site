
import enum from require "lapis.db.model"

class AdminUsers extends require "widgets.admin.page"
  @needs: {"users", "pager"}

  inner_content: =>
    @filter_form (field) ->
      field "email"
      field "sort", enum {
        "following_count"
        "modules_count"
        "followers_count"
        "stared_count"
      }

    @render_pager @pager
    @column_table @users, {
      "id"
      {"user", value: (user) -> user}
      "flags"
      "created_at"
      "last_active_at"
      "email"
      "following_count"
      "followers_count"
      "modules_count"
      "stared_count"
    }
    @render_pager @pager


