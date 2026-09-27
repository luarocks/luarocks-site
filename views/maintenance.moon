
class Maintenance extends require "widgets.page"
  inner_content: =>
    h2 "Temporarily unavailable"

    p "LuaRocks.org is in read-only maintenance mode. Logging in, registering,
      and uploading are temporarily disabled. Installing modules and browsing
      the site continue to work."

    p ->
      a href: @url_for("index"), "Go home"
