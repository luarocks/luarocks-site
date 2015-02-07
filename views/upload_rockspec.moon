class UploadRockspec extends require "widgets.base"
  inner_content: =>
    h2 "Upload Rockspec"
    @render_errors!

    p "Upload a rockspec to create a new module. If the module already exists,
      then the rockspec will be added to the list of available versions. If the
      version already exists then only the rockspec file will be overwritten."

    p "You should include a source rock with your rockspec to ensure it's
      installable. See the bottom of the page for directions."

    form action: @url_for"upload_rockspec", method: "POST", enctype: "multipart/form-data", ->
      input type: "hidden", name: "csrf_token", value: @csrf_token

      div class: "file_uploader", ->
        label ->
          strong "Choose a *.rockspec file"
          input type: "file", name: "rockspec_file"

      div class: "file_uploader", ->
        label ->
          strong "Choose a *.src.rock file"
          input type: "file", name: "rock_file"

      div class: "form_buttons", ->
        input type: "submit"

    hr!

    h3 "How to create a source rock"

    p "A source rock is different than a rockspec because it contains all the
    files necessary to build and install your module. A rockspec is only a
    manifest of the components that make up your module but not the actual
    files."

    p "Building a source rock is a good way to determine if you've created your
    rockspec correctly. It's also very easy to do if you've got LuaRocks
    installed."

    p "Run from the command line:"

    @term_snippet "luarocks pack my_module-1.0.rockspec"

    p "LuaRocks will download all the necessary files as described in the
    rockspec and package into the correctly named source rock in the current
    directory."

    p "You're now ready to upload both your source rock and your rockspec to
    LuaRocks.org!"

