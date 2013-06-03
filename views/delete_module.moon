class DeleteModule extends require "widgets.base"
  content: =>
    h2 "Are you sure you want to delete this module?"

    @render_modules { @module }

    p "All of the rockspecs and rocks that have been uploaded will also be deleted. This action is irreversible."
    p ->
      text "Type the name of the module, "
      strong @module.name
      text ", to continue."

    @render_errors!
    form action: @req.cmd_url, method: "POST", class: "form", ->
      div class: "button_row", ->
        input type: "hidden", name: "csrf_token", value: @csrf_token
        div class: "row", ->
          input type: "text", name: "module_name", id: "module_name"

        input type: "submit", value: "Delete Module"


