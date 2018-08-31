
line_style = {
  "stroke": "currentColor"
  "stroke-width": "2"
  "stroke-linecap": "round"
  "stroke-linejoin": "round"
  "fill": "none"
}


-- Icons from: https://feathericons.com/
class Icons
  @icons: {
    star: {
      width: 24
      height: 24

      svg_opts: line_style
      path: [[<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />]]
    }

    user_plus: {
      width: 24
      height: 24
      svg_opts: line_style
      path: [[<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><line x1="20" y1="8" x2="20" y2="14"></line><line x1="23" y1="11" x2="17" y2="11"></line>]]
    }

    user_check: {
      width: 24
      height: 24
      svg_opts: line_style
      path: [[<path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><polyline points="17 11 19 13 23 9"></polyline>]]
    }
  }

  icon: (name, width, opts) =>
    icon = Icons.icons[name]

    unless icon
      error "Failed to find icon: #{name}"

    width or= icon.width
    height = math.floor width / icon.width * icon.height

    svg_opts = {
      "aria-hidden": true
      class: "svgicon icon_#{name}"
      role: "img"
      version: "1.1"
      viewBox: "0 0 #{icon.width} #{icon.height}"
      :width, :height
    }

    if icon.svg_opts
      for k,v in pairs icon.svg_opts
        svg_opts[k] = v

    if opts
      for k,v in pairs opts
        if k == "class"
          svg_opts[k] ..= " " .. v
        else
          svg_opts[k] = v

    svg svg_opts, -> raw icon.path

-- vim: set nowrap:
