class UploadRockspec extends require "widgets.base"
  content: =>
    h2 "Upload Rockspec"
    @render_errors!

    p "Upload a rockspec to create a new module. If the module already exists, then the rockspec will be added to the list of available versions. If the version already exists then only the rockspec file will be overwritten."

    form action: @url_for"upload_rockspec", method: "POST", enctype: "multipart/form-data", ->
      div -> input type: "file", name: "rockspec_file"
      input type: "submit"


