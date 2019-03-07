
import types from require "tableshape"

import trim from require "lapis.util"
import strip_bad_chars from require "helpers.unicode"

db = require "lapis.db"

-- valid utf8, bad chars removed
valid_text = types.string / strip_bad_chars

trimmed_text = valid_text / trim * types.custom(
  (v) -> v != "", "expected text"
  describe: -> "not empty"
)

empty = types.one_of {
  types.nil
  types.pattern("^%s*$") / nil
}, describe: -> "empty"


-- create a table representing the difference in fields
difference = (update, source, check_removals=false) ->
  s = {}

  assert types.table\describe("update to be table") update
  assert types.table\describe("source to be table") source

  for field, new_value in pairs update
    if new_value == db.NULL
      new_value = nil

    matcher = types.equivalent(new_value) + types.any\tag (state, v) ->
      state.before = v
      state.after = new_value

    s[field] = types.scope matcher, tag: field

  if check_removals
    for field, old_value in pairs source
      continue if s[field]

      matcher = types.equivalent(nil) + types.any\tag (state, v) ->
        state.before = old_value

      s[field] = types.scope matcher, tag: field

  out = assert types.shape(s, open: true) source

  if out == true
    out = {}

  out

{:valid_text, :trimmed_text, :difference}
