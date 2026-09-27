
class SecurityIncidentSeptember2026 extends require "widgets.page"
  inner_content: =>
    @raw_ssi "security_incident_september_2026.html"

    a href: @url_for"index", "Return Home"
