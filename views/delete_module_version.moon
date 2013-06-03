class DeleteModuleVersion extends require "widgets.base"
  content: =>
    h2 "Delete Module Version"
    h3 "#{@module\name_for_display!} #{@version\name_for_display!}"

    p "All of the rocks that have been uploaded for this version will also be deleted. This action is irreversible."

    p ->
      text "Type the name of the module, "
      strong @module.name
      text ", to delete."

    @render_errors!
    form action: @req.cmd_url, method: "POST", class: "form", ->
      div class: "button_row", ->
        input type: "hidden", name: "csrf_token", value: @csrf_token
        div class: "row", ->
          input type: "text", name: "module_name", id: "module_name"

        input type: "submit", value: "Delete #{@version.version_name}"

    div ->
      a href: @url_for("module_version", @), ->
        raw "&laquo; No, Return to module"

