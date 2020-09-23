
db = require "lapis.db"
import insert, concat from table

increment_counter = (keys, amount=1) =>
  amount = tonumber amount
  keys = {keys} unless type(keys) == "table"

  update = {}
  for key in *keys
    update[key] = db.raw"#{db.escape_identifier key} + #{amount}"

  db.update @@table_name!, update, @_primary_cond!

generate_key = do
  rand = require "openssl.rand"

  alphabet = {}
  for i=65,90 -- A through Z
    table.insert alphabet, i

  for i=97,122 -- a through z
    table.insert alphabet, i

  for i=48,57 -- 0 through 9
    table.insert alphabet, i

  alphabet_len = #alphabet

  (length) ->
    string.char unpack [ alphabet[1 + rand.uniform alphabet_len] for i=1,length ]

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

  res = db.query q
  if next res
    @load (unpack res)
  else
    nil, "already exists"


upsert = (model, insert, update, cond) ->
  table_name = db.escape_identifier model\table_name!

  primary_keys = { model\primary_keys! }
  is_primary_key = {k, true for k in *primary_keys}

  unless update
    update = { k,v for k,v in pairs insert when not is_primary_key[k] }

  unless cond
    cond = { k,v for k,v in pairs insert when is_primary_key[k] }


  if model.timestamp
    time = db.format_date!
    update.updated_at = time
    insert.created_at = time
    insert.updated_at = time

  insert_fields = [k for k in pairs insert]
  insert_values = [db.escape_literal insert[k] for k in *insert_fields]
  insert_fields = [db.escape_identifier k for k in *insert_fields]

  assert next(insert_fields), "no fields to insert for upsert"

  res = db.query "
    with updates as (
      update #{table_name}
      set #{db.encode_assigns update}
      where #{db.encode_clause cond}
      returning *
    ),
    inserts as (
      insert into #{table_name} (#{table.concat insert_fields, ", "})
      select #{table.concat insert_values, ", "}
      where not exists(select 1 from updates)
      returning *
    )
    select *, 'update' as _upsert_type from updates
    union
    select *, 'insert' as _upsert_type from inserts
  "

  res = unpack res
  upsert_type = res._upsert_type
  res._upsert_type = nil
  upsert_type, model\load res

generate_uuid = () =>
  res = unpack db.query "select uuid_generate_v4()"
  return res.uuid_generate_v4



insert_on_conflict_ignore = (model, opts) ->
  import encode_values, encode_assigns from require "lapis.db"

  full_insert = {}

  if opts
    for k,v in pairs opts
      full_insert[k] = v

  if model.timestamp
    d = db.format_date!
    full_insert.created_at = d
    full_insert.updated_at = d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  insert buffer, " on conflict do nothing returning *"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res

insert_on_conflict_update = (model, primary, create, update, opts) ->
  import encode_values, encode_assigns from require "lapis.db"

  full_insert = {k,v for k,v in pairs primary}

  if create
    for k,v in pairs create
      full_insert[k] = v

  full_update = update or {k,v for k,v in pairs full_insert when not primary[k]}

  if model.timestamp
    d = db.format_date!
    full_insert.created_at or= d
    full_insert.updated_at or= d
    full_update.updated_at or= d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  if opts and opts.constraint
    insert buffer, " on conflict "
    insert buffer, opts.constraint
    insert buffer, " do update set "
  else
    insert buffer, " on conflict ("

    assert next(primary), "no primary constraint for insert on conflict update"

    for k in pairs primary
      insert buffer, db.escape_identifier k
      insert buffer, ", "

    buffer[#buffer] = ") do update set " -- remove ,

  encode_assigns full_update, buffer

  insert buffer, " returning *"

  if opts and opts.return_inserted
    insert buffer, ", xmax = 0 as inserted"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res

{ :generate_uuid, :increment_counter, :generate_key, :get_all_pages,
  :find_all_in_batches, :safe_insert, :upsert, :insert_on_conflict_update,
  :insert_on_conflict_ignore }
