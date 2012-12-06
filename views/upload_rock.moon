
class UploadRockspec extends require "widgets.base"
  content: =>
    h2 "Upload Rock"
    @render_errors!

    form {
      action: @url_for("upload_rock", @)
      method: "POST"
      enctype: "multipart/form-data"
    }, ->
      div -> input type: "file", name: "rock_file"
      input type: "submit"


