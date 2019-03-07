class SecurityIncident extends require "widgets.page"
  inner_content: =>
    @raw_ssi "security_incident_march_2019.html"

    a href: @url_for"index", "Return Home"
