
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

-- does a find all, splitting into many queries with at most batch_size ids per query
-- find_all_in_batches MyModel, {1,2,3,4,5}, batch_size: 2, fields: "hello, world"
find_all_in_batches = (model_cls, ids, ...) ->
  batch_size = 50

  if type(...) == "table"
    batch_size = (...).batch_size or batch_size

  total_ids = #ids

  return model_cls\find_all ids, ...  if total_ids < batch_size

  accum = nil
  for i=1, math.ceil #ids/batch_size
    page_ids = [ids[k] for k=(i - 1)*batch_size + 1, math.min total_ids, i*batch_size]

    res = model_cls\find_all page_ids, ...
    if accum
      for item in *res
        insert accum, item
    else
      accum = res

  accum

-- safe_insert Model, {color: true, id: 100}, {id: 100}
safe_insert = (data, check_cond=data) =>
  table_name = db.escape_identifier @table_name!

  if @timestamp
    data = {k,v for k,v in pairs data}
    time = db.format_date!
    data.created_at = time
    data.updated_at = time

  columns = [key for key in pairs data]
  values = [db.escape_literal data[col] for col in *columns]

  for i, col in ipairs columns
    columns[i] = db.escape_identifier col

  q = concat {
    "insert into"
    table_name
    "("
    concat columns, ", "
    ")"
    "select"
    concat values, ", "
    "where not exists ( select 1 from"
    table_name
    "where"
    db.encode_clause check_cond
    ") returning *"
  }, "  "

  db.query q

{ :increment_counter, :generate_key, :get_all_pages, :find_all_in_batches, :safe_insert }
