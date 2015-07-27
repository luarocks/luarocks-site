db = require "lapis.db"

cumulative_created = (model, clause, field="created_at", trunc="day") ->
  clause = if clause
    "where " .. db.encode_clause clause

  table_name = db.escape_identifier model\table_name!
  field = db.escape_identifier field

  db.query "select
    date_trunc(?, #{field})::date as date,
    sum(sum(1)) over (order by date_trunc(?, #{field})::date) as count
    from #{table_name}
    #{clause or ""}
    group by date_trunc(?, #{field})::date
  ", trunc, trunc, trunc

daily_created = (model, clause, field="created_at") ->
  clause = if clause
    "where " .. db.encode_clause clause

  table_name = db.escape_identifier model\table_name!
  field = db.escape_identifier field

  db.query "select
    date_trunc('day', #{field})::date as date,
    count(*)
    from #{table_name}
    #{clause or ""}
    group by date_trunc('day', #{field})::date
    order by date asc
  "

{ :cumulative_created, :daily_created }
