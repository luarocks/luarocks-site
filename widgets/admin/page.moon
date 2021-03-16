PageHeader = require "widgets.page_header"

-- base class for all admin pages
class AdminPage extends require "widgets.page"
  render_nav_tab: (name, label, href) =>
    href or= @url_for name
    a href: href, class: "tab #{name == @route_name and "active" or ""}", label

  header_content: =>
    widget PageHeader {
      inner_content: ->
        div class: "page_header_inner" , ->
          h1 ->
            if @title
              text @title
              text " — "

            text "Admin"

        div class: "page_tabs", ->
          @render_nav_tab "admin.users", "Users"
          @render_nav_tab "admin.labels", "Labels"
          @render_nav_tab "admin.cache", "Cache"
    }


  render_model: (instance) =>
    switch instance.__class.__name
      when "Users"
        a href: @url_for(instance), instance\name_for_display!
        text " ("
        a href: @url_for("admin.user", id: instance.id), "admin"
        text ")"
      when "Modules"
        a href: @url_for(instance), instance\name_for_display!
      else
        em "<don't know how to render model (#{instance.__class.__name})>"

  format_table_value_by_type: (value_type, field, value, field_name) =>
    switch value_type
      when "model"
        -> @render_model value
      else
        super value_type, field, value, field_name
