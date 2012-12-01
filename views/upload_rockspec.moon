import Widget from require "lapis.html"
class UploadRockspec extends Widget
  content: =>
    h2 "Upload Rockspec"
    form action: @url_for"upload_rockspec", method: "POST", enctype: "multipart/form-data", ->
      div -> input type: "file", name: "rockspec_file"
      input type: "submit"


