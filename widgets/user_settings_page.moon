
class UserSettings extends require "widgets.page"
  inner_content: =>
    h2 "Account settings"

    div class: "page_tabs", ->
      @render_nav_tab "user_settings.profile", "Profile"
      @render_nav_tab "user_settings.reset_password", "Reset password"
      @render_nav_tab "user_settings.api_keys", "API keys"
      @render_nav_tab "user_settings.link_github", "GitHub link"
      -- @render_nav_tab "user_settings.import_toolbox", "Lua Toolbox"

    @render_errors!
    @settings_content!

  settings_content: =>

  render_nav_tab: (name, label, href) =>
    href or= @url_for name
    a href: href, class: "tab #{name == @route_name and "active" or ""}", label



