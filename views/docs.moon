class Docs extends require "widgets.page"
  manifest_sections: {
    {"Using-Manifests-with-LuaRocks", "Using Manifests"}
    {"Manifest-Root-Paths", "Root Paths"}
    {"Available-Paths-Under-Each-Root", "Available Paths"}
    {"Manifest-File-Structure", "File Structure"}
    {"Accessing-Module-Files", "Accessing Files"}
    {"Output-Formats", "Output Formats"}
    {"Custom-Manifests", "Custom Manifests"}
    {"Usage-Examples", "Usage Examples"}
    {"Mirrors", "Mirrors"}
  }

  inner_content: =>
    div class: "docs_page", ->
      section class: "docs_hero", ->
        h1 "LuaRocks Documentation"
        p class: "docs_hero_sub",
          "Guides and references for using LuaRocks, the package manager for the Lua programming language."

      section class: "doc_cards", ->
        a class: "doc_card", href: "/docs/api", ->
          h2 "LuaRocks.org HTTP API"
          p ->
            text "HTTP API used by the "
            code "luarocks upload"
            text " command for publishing rocks to LuaRocks.org."
          span class: "doc_card_cta", "Read the API reference →"

        a class: "doc_card", href: "https://github.com/luarocks/luarocks/blob/main/docs/index.md", ->
          h2 "LuaRocks CLI"
          p "Complete documentation for the LuaRocks command-line tool: installation, configuration, and usage guides."
          span class: "doc_card_cta", "Open the CLI guide →"

      nav class: "docs_toc", ->
        div class: "docs_toc_title", "Manifests"
        ul ->
          for {anchor, label} in *@manifest_sections
            li ->
              a href: "##{anchor}", label

      div class: "docs_body", ->
        @raw_ssi "docs.html"
