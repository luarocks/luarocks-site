class AdminCache extends require "widgets.page"
  @include "widgets.table_helpers"

  inner_content: =>
    h2 "Purge cache"
    form method: "post", class: "form", ->
      @csrf_input!
      button class: "button", name: "action", value: "purge_all", "Purge all"

    h3 "Keys"
    @column_table @cache_keys, {
      {"Key", (tuple) ->
        code tuple[1]
      }
      {"Stored at", (tuple) ->
        @render_date tuple[2]
      }
      {"Purge", (tuple) ->
        form method: "post", ->
          @csrf_input!
          input type: "hidden", name: "key", value: tuple[1]
          button class: "button", name: "action", value: "purge", "Purge"
      }
    }



