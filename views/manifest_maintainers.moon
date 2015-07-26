ManifestHeader = require "widgets.manifest_header"

class ManifestMaintainers extends require "widgets.page"
  inner_content: =>
    widget ManifestHeader page_name: "maintainers"

    unless next @admins
      p class: "empty_message", "There don't appear to be any maintainers"

    ul ->
      for admin in *@admins
        li ->
          a href: @url_for(admin.user), admin.user\name_for_display!

