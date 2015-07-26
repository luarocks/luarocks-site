dir = "spec/screenshots"
import slugify from require "lapis.util"

-- get the file name of a spec context
get_file_name = (context) ->
  busted = require "busted"

  names = { context.name or context.descriptor }

  while true
    context = busted.parent context
    break unless context
    name = context.name or context.descriptor
    break if context.descriptor == "file"
    table.insert names, 1, name

  names = for name in *names
    slugify assert name\gsub("#%w*", "")\match("^%s*(.-)%s*$"), "no spec name"

  table.concat names, "."

screenshot_path = do
  counts = {}
  (spec_name) ->
    full_name = if counts[spec_name]
      counts[spec_name] += 1
      "#{spec_name}.#{counts[spec_name]}"
    else
      counts[spec_name] = 1
      spec_name

    "#{dir}/#{full_name}.png"

{ :get_file_name, :screenshot_path }
