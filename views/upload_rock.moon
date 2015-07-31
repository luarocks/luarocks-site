
class UploadRock extends require "widgets.page"
  @needs: {
    "version"
  }

  inner_content: =>
    h2 ->
      text "Upload Rock For "
      a href: @url_for(@version),
        "#{@module\name_for_display!} #{@version.version_name}"

    @render_errors!

    if @version.development
      p ->
        strong "Note: "
        text "This version is marked as development. If you intend for it to be
        installed from the repository you should not upload a rock. A rock will
        take precedence over the rockspec during install and prevent
        installation directly from repository."

    form {
      action: @url_for("upload_rock", @)
      method: "POST"
      enctype: "multipart/form-data"
    }, ->
      @csrf_input!
      div class: "file_input_row", -> input type: "file", name: "rock_file"
      input type: "submit"


