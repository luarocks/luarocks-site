
moon = require "moon"
app = require"app"!

import columnize from require "lapis.cmd.util"

tuples = [{k,v} for k,v in pairs app.router.named_routes]
table.sort tuples, (a,b) ->
  a[1] < b[1]

print columnize tuples, 0, 4, false

