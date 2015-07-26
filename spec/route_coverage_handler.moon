colors = require "ansicolors"
import columnize from require "lapis.cmd.util"

(options) ->
  busted = require "busted"
  handler = require("busted.outputHandlers.utfTerminal") options

  local spec_name

  router = require("app")!.router
  router\build!

  route_counts = {}

  busted.subscribe { "suite", "end" }, (context) ->
    hits = 0
    misses = 0

    columns = for {pattern, _, name} in *router.routes
      count = route_counts[pattern] or 0
      status = if count == 0
        misses += 1
        colors "%{bright red}%{red}0"
      else
        hits += 1
        colors "%{green}#{count}"

      {pattern, status}

    table.sort columns, (a, b) ->
      a[1] < b[1]

    print!
    print "Route coverage report:"
    print columnize columns, 0, nil, false

    print colors "Routes hit: %{green}#{hits}%{reset}, " ..
      "Routes missed: %{bright red}#{misses}%{reset}, " ..
      "Percent: %{yellow}#{"%0.2f"\format 100 * hits / (misses + hits)}%"

  busted.subscribe { "lapis", "request" }, (url, opts) ->
    path = url\gsub "%?.*$", ""

    domain, real_path = path\match "http://([^/]+)(/.*)$"
    if domain
      path = real_path
      if subdomain = domain\match "([^.]+)%.[^.]+%."
        path = "/g/#{subdomain}#{path}"

    params, _, pattern, name = router.p\match path

    if params
      route_counts[pattern] or= 0
      route_counts[pattern] += 1

  handler
