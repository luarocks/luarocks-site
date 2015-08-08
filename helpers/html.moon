import escape from require "lapis.html"


basic_format = do
  import P, R, C, Cs, S, Cmt, Ct, Cg from require "lpeg"
  stop = P"\r"^-1 * P"\n"

  char = stop / "<br />" + 1

  paragraph_body = Cs (char - stop * stop)^1
  paragraphs = Ct paragraph_body * (stop^1 * paragraph_body)^0

  (str) ->
    str = escape str
    body = if ps = paragraphs\match str
      table.concat(ps, "</p><p>")
    else
      str

    "<p>#{body}</p>"


{ :basic_format }
