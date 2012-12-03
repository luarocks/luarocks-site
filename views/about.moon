class About extends require "widgets.base"
  content: =>
    h2 "About"
    p ->
      text "MoonRocks aims to be a community rock hosting service for Lua by providing an easy way to upload rocks and rockspecs compatible with "
      a href: "http://luarocks.org/", "LuaRocks"
      text "."

    p ->
      text "Anyone can join and upload a Lua module, which gets placed in their own Manifest. A Manifest is a list of packages that LuaRocks can install from."

    p ->
      text "In addition to the user manifests, there is also the root manifest. Users can elect their modules into it to make it eaiser for people to install their module when using the root manifest url."

    h3 "More About Rockspecs & Rocks"

    p ->
      text "A module is made up of two parts, a "
      code ".rockspec"
      text " file, and optionally various "
      code ".rock"
      text " files."

    p ->
      text "A rockspec is a package declaration, one must be created for every version. A rockspec describes metadata about the packge, including where to download the source and how to build it. To host a package on MoonRocks you minimally need to upload a rockspec."

    p ->
      text "Rocks are zips files containig a rockspec and all the files needed to install it. Different rocks can exist for a single version, differing in the architecture they target. The filename of the rock is used to determine the kind of contents it has. After uploading a rockspec to create a module, you can upload rocks for that module."


    h3 "How This Site Is Built"

    p ->
      text "coming soon... View the source on "
      a href: "http://github.com/leafo/moonrocks-site", "GitHub"
      text "."

    a href: @url_for"index", "Return Home"
