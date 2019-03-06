db = require "lapis.db"
date = require "date"

import unescape, parse_query_string, to_json from require "lapis.util"
html = require "lapis.html"

import P, S, Cg, R, Ct from require "lpeg"

format_date = (d) -> assert(date d)\fmt "%Y-%m-%d %H:%M:%S"

match_key = P" /api/1/" * Cg((1 - S"/ ")^1, "api_key")
match_date = P" [" * Cg(R"09"^1 * (1 - P"]")^0 / format_date, "date") * P"] "
match_forgot_url = P" /user/forgot_password?" * Cg (1 - P" ")^1 / html.unescape / parse_query_string, "reset_password"

find = (p) -> (P(1) - p)^0 * p

match_api_line = Ct find(match_date) * find(match_key) * Cg (1 - P" ")^0 / unescape, "rest"
match_forgot_line = Ct find(match_date) * find(match_forgot_url)

match_line = match_api_line + match_forgot_line

db.query "truncate user_server_logs"

import ApiKeys, UserServerLogs from require "models"
keys_by_id = {key.key, key for key in *ApiKeys\select!}

for line in io.stdin\lines!
  row = match_line\match line
  continue unless row

  user_id = if row.api_key
    if key = keys_by_id[row.api_key]
      assert key.user_id, "missing user id"
  elseif row.reset_password
    tonumber row.reset_password.id

  UserServerLogs\create {
    log: line
    log_date: assert row.date, "missing date"
    data: to_json row
    :user_id
  }
