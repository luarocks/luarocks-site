
import Rocks, Versions from require "models"

do_it = ...

for rock in *Rocks\select "where not exists(select 1 from versions where versions.id = rocks.version_id)"
  if do_it
    rock\delete!
  else
    print "Deleting", require("moon").dump rock

