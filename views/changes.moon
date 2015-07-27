class Changes extends require "widgets.page"
  inner_content: =>
    div class: "changes_page", -> @raw_ssi "changes.html"
    a href: @url_for"index", "Return Home"
