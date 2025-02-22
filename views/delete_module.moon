class DeleteModule extends require "widgets.page"
  inner_content: =>
    h2 "Are you sure you want to delete this module?"

    @render_modules { @module }

    p "All of the rockspecs and rocks that have been uploaded will also be deleted. This action is irreversible."
    p ->
      text "Type the name of the module, "
      strong @module.name
      text ", to delete."

    @render_errors!
    form action: @req.cmd_url, method: "POST", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      label class: "wide_row", ->
        div class: "label", "Module Name"
        input type: "text", name: "module_name", required: true

      div class: "button_row", ->
        input type: "submit", value: "Delete Module"
        text " "
        a href: @url_for("module", @), class: "aside", ->
          raw "&laquo; No, Return to module"

