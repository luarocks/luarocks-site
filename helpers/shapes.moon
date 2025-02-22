
types = require "lapis.validate.types"
db = require "lapis.db"

email = types.trimmed_text * types.pattern("^[^@%s]+@[^@%s%.]+%.[^@%s]+$")\describe "email"

-- replace empty value with default
default = (value) -> types.empty / value + types.any

url = types.trimmed_text * types.one_of({
  types.pattern("^https?://[^%s]+$")
  types.pattern("^[^%s]+$") / (str) -> "http://#{str}"
})\describe "url"

twitter_username = types.trimmed_text * types.string\length(1,20) * types.pattern(
  "^@?[_a-zA-Z0-9]+$"
)\describe("twitter username") / (str) ->
  unless str\match "^@"
    "@#{str}"
  else
    str

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

{
  :email
  :url
  :twitter_username
  :default

  :difference
}
