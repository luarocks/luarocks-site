class AdminCache extends require "widgets.page"
  inner_content: =>
    h2 "Purge cache"
    form method: "post", class: "form", ->
      @csrf_input!
      button class: "button", name: "action", value: "purge", "Purge"

    h3 "Keys"
    pre ->
      for key in *@cache_keys
        text key
        br!



