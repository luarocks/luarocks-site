
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

email = trimmed_text * types.pattern("^[^@%s]+@[^@%s%.]+%.[^@%s]+$")\describe "email"

url = trimmed_text * types.one_of {
  types.pattern("^https?://[^%s]+$")
  types.pattern("^[^%s]+$") / (str) -> "http://#{str}"
}, describe: -> "url"

truncated_text = (len) ->
  assert len, "missing length for shapes.truncated_text"

  trimmed_text * types.one_of({
    types.string\length 0, len
    types.string / (s) ->
      import acceptable_character from require "helpers.unicode"
      import C, Cmt from require "lpeg"

      count = 0
      pattern = C Cmt(acceptable_character, ->
        count += 1
        count <= len
      )^0

      pattern\match s

  }) * trimmed_text

limited_text = (max_len, min_len=1) ->
  out = trimmed_text * types.string\length min_len, max_len
  out\describe "text between #{min_len} and #{max_len} characters"

twitter_username = trimmed_text * types.string\length(1,20) * types.pattern(
  "^@?[_a-zA-Z0-9]+$", describe: -> "twitter usename"
) / (str) ->
  unless str\match "^@"
    "@#{str}"
  else
    str

import slugify from require "lapis.util"

slug = truncated_text(80) / slugify * types.custom (str) ->
  if str\match "^%-*$"
    nil, "please use only letters, numbers, _ or -"
  elseif str\match("^%-") or str\match "%-$"
    nil, "please remove _ and - at the start and end"
  else
    true

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

to_db_array = types.one_of {
  -- already an array, do nothing
  types.custom((v) -> db.is_array v)\describe "db.array"
  types.equivalent({})\describe("empty table") / db.NULL
  types.table\describe("table array") / (v) -> db.array [v for v in *v]
}

transformer_type = types.shape({
  transform: types.function
}, open: true)\describe "type transformer"

param_transform_with_options = types.assert types.shape({
  transformer_type\tag "t"
  error: types.nil + types.string\tag "error"
  label: types.nil + types.string\tag "label"
})

params = (shape) ->
  (p) ->
    local errors
    out = {}
    local state

    for key, t in pairs shape
      local options

      unless transformer_type t
        options = param_transform_with_options t
        t = options.t
        if options.field
          key = options.field

      out[key], state_or_err = t\transform p[key], state

      -- got an error
      if out[key] == nil and type(state_or_err) == "string"
        err = if options and options.error
          options.error
        else
          "#{options and options.label or key}: #{state_or_err}"

        if errors
          table.insert errors, err
        else
          errors = {err}
      else
        state = state_or_err

    if errors and next errors
      return nil, errors
    else
      if state
        out, state
      else
        out

assert_params = (tbl, shape) ->
  fn = params(shape)
  out, errs = fn tbl

  if out
    out, errs
  else
    coroutine.yield "error", errs
    error "coroutine did not yield"

{
  :valid_text
  :trimmed_text
  :truncated_text
  :empty
  :email
  :url
  :limited_text
  :twitter_username
  :slug

  :difference, :to_db_array
  :params, :assert_params
}
