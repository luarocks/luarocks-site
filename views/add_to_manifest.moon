class AddToManifest extends require "widgets.base"
  content: =>
    h2 "Add Module To Manifest"
    
    @render_modules { @module }

    a href: @url_for("module", @), ->
      raw "&laquo; Return to module"

    h3 "Add To"
    if next @manifests
      @add_form!
    else
      text "There are no manifests this module can be added to at this time."

  add_form: =>
    @render_errors!
    form action: @req.cmd_url, method: "POST", class: "form", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      div class: "row", ->
        label "Manifests"
        element "select", name: "manifest_id", ->
          for m in *@manifests
            option value: m.id, m.name

      div class: "button_row", ->
        input type: "submit", value: "Add Module"
