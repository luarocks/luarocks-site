class AdminCache extends require "widgets.admin.page"
  inner_content: =>
    h2 "Purge cache"
    form method: "post", class: "form", ->
      @csrf_input!
      button class: "button", name: "action", value: "purge_all", "Purge all"
      text " "
      button class: "button", name: "action", value: "purge_root", "Purge root manifest"

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



