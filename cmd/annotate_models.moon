config = require("lapis.config").get!

exec = (cmd) ->
  f = io.popen cmd
  with f\read("*all")\gsub "%s*$", ""
    f\close!

extract_header = (model_name) ->
  model = require "models.#{model_name}"
  table_name = model\table_name!
  schema = exec "pg_dump --schema-only -U postgres -t #{table_name} #{assert config.postgres.database, "missing db"}"

  in_block = false

  filtered = for line in schema\gmatch "[^\n]+"
    if in_block
      in_block = false unless line\match "^%s"
      continue if in_block

    continue if line\match "^%-%-"
    continue if line\match "^SET"
    continue if line\match "^ALTER SEQUENCE"

    if line\match("^ALTER TABLE" ) and not line\match("^ALTER TABLE ONLY") or line\match "nextval"
      continue

    if line\match "CREATE SEQUENCE"
      in_block = true
      continue

    "-- " .. line\gsub "    ", "  "


  table.insert filtered, 1, "--"
  table.insert filtered, 1, "-- Generated schema dump: (do not edit)"
  table.insert filtered, "--"

  table.concat filtered, "\n"


for model in exec("ls models/*.moon")\gmatch "([%w_]+)%.moon"
  print "Processing #{model}"
  fname = "models/#{model}.moon"
  header = extract_header model

  source_f = io.open fname, "r"
  source = source_f\read "*all"
  source_f\close!

  source_with_header = if source\match "%-%- Generated .-\nclass "
    source\gsub "%-%- Generated .-\nclass ", "#{header}\nclass ", 1
  else
    source\gsub "class ", "#{header}\nclass ", 1

  source_out = io.open fname, "w"
  source_out\write source_with_header
  source_out\close!


