PageHeader = require "widgets.page_header"

class UserSettings extends require "widgets.page"
  header_content: =>
    widget PageHeader {
      inner_content: ->
        div class: "page_header_inner" , ->
          h1 "Account settings"

        div class: "page_tabs", ->
          @render_nav_tab "user_settings.profile", "Profile"
          @render_nav_tab "user_settings.reset_password", "Password"
          @render_nav_tab "user_settings.api_keys", "API keys"
          @render_nav_tab "user_settings.link_github", "GitHub link"
          @render_nav_tab "user_settings.import_toolbox", "Lua Toolbox"
          @render_nav_tab "user_settings.security_audit", "Security Audit"
          @render_nav_tab "user_settings.sessions", "Sessions"
          @render_nav_tab "user_settings.activity", "Activity"
    }

  inner_content: =>
    @render_errors!
    @settings_content!

  settings_content: =>

  render_nav_tab: (name, label, href) =>
    href or= @url_for name
    a href: href, class: "tab #{name == @route_name and "active" or ""}", label



