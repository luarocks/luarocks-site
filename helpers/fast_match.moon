
import types from require "tableshape"
import P, C, V, R from require "lpeg"

-- local mt
-- mt = {
--   __add: (...) -> setmetatable {"add", ...}, mt
--   __mul: (...) -> setmetatable {"mul", ...}, mt
-- }
-- 
-- P = (...) -> setmetatable { "P", ... }, mt
-- C = (...) -> setmetatable { "C", ... }, mt


single_array = types.shape { types.string }
single_group = types.shape { single_array }

group_by_prefix = (strings, len=1, valid="[a-zA-Z0-9%. %-/]") ->
  if #strings < 2
    return { strings }

  out = {}
  pattern = "^(#{valid\rep len})"

  for s in *strings
    k, suffix = if front = s\match pattern
      if front == s
        1,s
      else
        front, s\sub #front + 1
    else
      1, s

    out[k] or= {}
    table.insert out[k], suffix


  real_out = {
    out[1]
  }

  for prefix, suffixes in pairs out
    continue if prefix == 1

    -- try to grow the suffix
    sub_group = group_by_prefix suffixes, len, valid

    k = next sub_group

    fp, fv = if types.string(k) and types.shape({[k]: types.table, [1]: types.nil})(sub_group)
      prefix .. k, sub_group[k]
    else
      prefix, sub_group

    if single_group fv
      real_out[1] or= {}
      table.insert real_out[1], "#{fp}#{fv[1][1]}"
    else
      real_out[fp] = fv

  real_out

add = (a,b) -> a + b
mul = (a,b) -> a * b

join_patterns = (patts, op=add) ->
  local patt

  for p in *patts
    if patt
      patt = op patt, p
    else
      patt = p

  patt

join_groups = (groups) ->
  join_patterns for k,v in pairs groups
    if k == 1
      join_patterns [P(s) for s in *v]
    else
      if single_array v
        P k .. v[1]
      else
        P(k) * join_groups v

fast_match = (strings) ->
  strings = [s for s in pairs {s, true for s in *strings}]
  groups = group_by_prefix strings
  -- tailed by non-character
  join_groups(groups) * (P(-1) + -R("AZ", "az", "09"))

fast_match_anywhere = (strings) ->
  P {
    C(fast_match(strings)) + 1 * V(1)
  }

{:fast_match, :fast_match_anywhere, :group_by_prefix}

