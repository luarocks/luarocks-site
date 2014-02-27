
db = require "lapis.db"
import insert from table

increment_counter = (keys, amount=1) =>
  amount = tonumber amount
  keys = {keys} unless type(keys) == "table"

  update = {}
  for key in *keys
    update[key] = db.raw"#{db.escape_identifier key} + #{amount}"

  db.update @@table_name!, update, @_primary_cond!

generate_key = do
  import random from math
  random_char = ->
    switch random 1,3
      when 1
        random 65, 90
      when 2
        random 97, 122
      when 3
        random 48, 57

  (length) ->
    string.char unpack [ random_char! for i=1,length ]

get_all_pages = (pager) ->
  i = 1
  accum = {}
  while true
    items = pager\get_page i
    break unless next items
    for item in *items
      insert accum, item
    i += 1

  accum


{ :increment_counter, :generate_key, :get_all_pages }
