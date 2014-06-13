class Search extends require "widgets.base"
  inner_content: =>
    h2 "Search"
    @render_search_form!

    if @results
      @render_search_results!

    if @user_results and next @user_results
      @render_user_results!

  render_search_form: =>
    form action: "", method: "get", class: "form", ->
      div class: "row", ->
        label for: "search_input", "Query"
        input type: "text", name: "q", id: "search_input", value: @params.q, autofocus: "autofocus"

      div class: "row", ->
        label for: "root_toggle", "Include non-root"
        input type: "checkbox", name: "non_root", id: "root_toggle", checked: @params.non_root and "checked" or nil

      div ->
        input type: "submit", value: "Search"

  render_search_results: =>
    h2 "Modules"

    unless next @results
      p class: "empty_message", "No results"
      return

    @render_modules @results

  render_user_results: =>
    h2 "Users"
    div class: "user_list", ->
      for user in *@user_results
        div class: "user_row", ->
          a href: @url_for("user_profile", user: user), user.username


