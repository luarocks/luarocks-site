ManifestHeader = require "widgets.manifest_header"

class ManifestMaintainers extends require "widgets.base"
  inner_content: =>
    widget ManifestHeader page_name: "maintainers"
