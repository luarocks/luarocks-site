class ApiDocs extends require "widgets.page"
  endpoints: {
    {"Get-Tool-Version", "GET", "/api/tool_version"}
    {"Get-API-Key-Status", "GET", "/api/1/:key/status"}
    {"Check-Rockspec", "GET", "/api/1/:key/check_rockspec"}
    {"Verify-TFA", "POST", "/api/1/:key/verify_tfa"}
    {"Upload-Rockspec", "POST", "/api/1/:key/upload"}
    {"Upload-Rock", "POST", "/api/1/:key/upload_rock/:version_id"}
  }

  inner_content: =>
    div class: "docs_page", ->
      section class: "docs_hero", ->
        a class: "docs_back", href: @url_for("docs"), "← All documentation"
        h1 "LuaRocks.org HTTP API"
        p class: "docs_hero_sub",
          "HTTP API for programmatically uploading rockspecs and rocks. This is the same API used by the luarocks upload command."

      nav class: "docs_toc api_endpoint_toc", ->
        div class: "docs_toc_title", "Endpoints"
        ul ->
          for {anchor, method, path} in *@endpoints
            li ->
              a href: "##{anchor}", ->
                span class: "endpoint_method endpoint_method_#{method\lower!}", method
                span class: "endpoint_path", path

      div class: "docs_body api_docs_body", ->
        @raw_ssi "api.html"
