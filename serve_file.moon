
slug = ngx.var[1]
file = ngx.var[2]

-- send request to app
return ngx.exec "/" if file == "manifest"

import Users, Modules, Versions, Rocks from require "models"
user = Users\find(:slug)

should_increment = ->
  if agent = ngx.var.http_user_agent
    agent = agent\lower!
    if agent\match"luasocket" or agent\match"wget"
      true

key = "#{user.id}/#{file}"

if file\match "%.rockspec$"
  version = Versions\find rockspec_key: key
  ngx.exit 404 unless version

  version\increment_download! if should_increment!
  ngx.var._url = version\rockspec_url!
else
  rock = Rocks\find rock_key: key
  ngx.exit 404 unless rock

  ngx.var._url = rock\rock_url!

