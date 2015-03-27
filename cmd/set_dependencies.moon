
import Versions, Modules from require "models"

for page in Versions\paginated("order by id asc", per_page: 100)\each_page!
  Modules\include_in page, "module_id"
  for v in *page
    print "Updating #{v.module.name} #{v\name_for_display!}"
    v\update_dependencies!

