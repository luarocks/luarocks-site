class DeleteRock extends require "widgets.page"
  inner_content: =>
    h2 "Delete Rock"
    h3 "#{@module\name_for_display!} #{@version\name_for_display!} #{@rock.arch}"

    p "The rock's archive will be deleted. This action is irreversible."

    form action: "", method: "POST", class: "form", ->
      @csrf_input!

      div class: "button_row", ->
        input type: "submit", value: "Delete #{@rock.rock_fname}"

    p ->
      a href: @url_for("edit_module_version", @), ->
        raw "&laquo; Nevermind, return to module"

