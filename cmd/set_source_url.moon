
import connect_postgres from require "cmd.helpers"
connect_postgres!

import Versions from require "models"
versions = Versions\select!
print "Processing #{#versions} rockspecs"

for version in *versions
  spec = version\get_spec!
  url = assert spec.source.url, "missing url"
  version\update source_url: url

