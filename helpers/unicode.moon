import P, Cs, R, S from require "lpeg"

cont = R("\128\191")
utf8_codepoint = R("\194\223") * cont +
  R("\224\239") * cont * cont +
  R("\240\244") * cont * cont * cont

has_utf8_codepoint = do
  p = (1 - utf8_codepoint)^0 * utf8_codepoint
  (str) -> not not p\match str

acceptable_character = S("\r\n\t") + R("\032\126") + utf8_codepoint
acceptable_string = acceptable_character^0 * P -1

strip_invalid_utf8 = do
  p = Cs (R("\0\127") + utf8_codepoint + P(1) / "")^0
  (text) -> p\match text

strip_bad_chars = do
  p = Cs (acceptable_character + P(1) / "")^0 * -1
  (text) -> p\match text

{:utf8_codepoint, :has_utf8_codepoint, :strip_invalid_utf8, :acceptable_character, :acceptable_string, :strip_bad_chars}

