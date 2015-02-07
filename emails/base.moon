
import Widget from require "lapis.html"

class Email extends Widget
  @render: (r, params) =>
    i = @(params)
    i\include_helper r
    i\subject!, i\render_to_string!, html: true

  @send: (r, recipient, ...) =>
    import send_email from require "helpers.email"
    send_email recipient, @render r, ...

  url_for: (...) =>
    url_for = @_find_helper "url_for"
    @build_url url_for nil, ...

  subject: => "LuaRocks"

  content: =>
    div -> @body!
    @hr!
    @footer!

  body: => error "fill me out"

  footer: =>
    h4 ->
      a href: "http://luarocks.org", "LuaRocks"

  hr: =>
    hr style: "border: 0; height: 1px; background: #dadada"
