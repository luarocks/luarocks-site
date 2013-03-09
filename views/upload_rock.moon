
class UploadRock extends require "widgets.base"
  content: =>
    h2 "Upload Rock"
    @render_errors!

    form {
      action: @url_for("upload_rock", @)
      method: "POST"
      enctype: "multipart/form-data"
    }, ->
      input type: "hidden", name: "csrf_token", value: @csrf_token
      div -> input type: "file", name: "rock_file"
      input type: "submit"


