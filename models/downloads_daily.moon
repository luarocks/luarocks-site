
db = require "lapis.db"
import Model from require "lapis.db.model"

import concat from table

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE downloads_daily (
--   version_id integer NOT NULL,
--   date date NOT NULL,
--   count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY downloads_daily
--   ADD CONSTRAINT downloads_daily_pkey PRIMARY KEY (version_id, date);
--
class DailyCounter extends Model
  @tmz: -7

  @date: (days=0) =>
    time = os.time! + @tmz*60*60 + days*60*60*24
    os.date "!%Y-%m-%d", time

  @increment: (version_id, amount=1) =>
    table = db.escape_identifier @table_name!
    amount = tonumber amount

    date = @date!
    db.query [[
      insert into ]]..table..[[ (version_id, date)
        select ?, ?
        where not exists (select 1 from ]]..table..[[
          where version_id = ? and date = ?)
      ]], version_id, date, version_id, date

    db.query [[
      update ]]..table..[[
        set count = count + ?
        where version_id = ? and date = ?
    ]], amount, version_id, date


  @fetch: (version_ids, days=7) =>
    clause = if version_ids == true
      ""
    else
      return {} if #version_ids == 0

      if type(version_ids) == "table"
        version_ids = concat version_ids, ", "

      "and version_id in (#{version_ids})"

    tbl = db.escape_identifier @table_name!
    range = @date -days

    db.query [[
      select sum(count) as count, date from ]] .. tbl .. [[
      where date >= ? ]] .. clause .. [[
      group by date
      order by date asc
    ]], range

class DownloadsDaily extends DailyCounter
