
Header = require "widgets.user_header"

class UserProfile extends require "widgets.page"
  content: =>
    div class: @@css_classes!, ->
      @header!
      div class: "main_column", ->
        @inner_content!

  header: =>
    widget Header!

  inner_content: =>
    @term_snippet "luarocks install --server=#{@user\source_url @} <name>"
    
    h3 "Modules"
    @render_pager @pager
    @render_modules @modules
    @render_pager @pager

    if @current_user and @current_user\is_admin!
      fieldset ->
        legend "Admin tools"
        form action: @url_for("admin_become_user"), method: "POST", ->
          input type: "hidden", name: "user_id", value: @user.id
          @csrf_input!
          button class: "button", "Become user"

