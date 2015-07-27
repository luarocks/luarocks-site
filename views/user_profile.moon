
class extends require "widgets.page"
  inner_content: =>
    h2 ->
      text "#{@user.username}'s Modules"
      text " "
      span class: "header_count", "(#{@pager\total_items!})"

    @term_snippet "luarocks install --server=#{@user\source_url @} <name>"
    
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

