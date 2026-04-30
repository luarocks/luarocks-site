
argparse = require "argparse"

parser = argparse "populate_hashes.moon", "Backfill sha256/md5 hashes and size for rockspecs and rocks"

parser\argument("module_id", "Module IDs to refresh; if provided, always refresh regardless of existing hashes")\args("*")\convert tonumber
parser\flag "--confirm", "Apply updates (otherwise dry-run)"
parser\flag "--versions-only", "Only process rockspec versions"
parser\flag "--rocks-only", "Only process rocks"
parser\option("--limit", "Max rows to process per type (versions and rocks each)")\convert tonumber

args = parser\parse [v for _, v in ipairs _G.arg]

import Rocks, Versions from require "models"
import compute_hashes from require "helpers.uploaders"

db = require "lapis.db"
bucket = require "storage_bucket"

backfill = (label, rows, get_key) ->
  n = 0
  for row in *rows
    n += 1
    key = get_key row
    ok, bytes = pcall -> bucket\get_file key
    unless ok and bytes
      io.stderr\write "  #{label} ##{row.id} (#{key}) - fetch failed\n"
      continue
    hashes = compute_hashes bytes
    if args.confirm
      row\update sha256: hashes.sha256, md5: hashes.md5, size: hashes.size
      print "  #{label} ##{row.id} - sha256=#{hashes.sha256} size=#{hashes.size}"
    else
      print "  #{label} ##{row.id} (#{key}) - would set sha256=#{hashes.sha256} size=#{hashes.size}"
    if n % 100 == 0
      print "  ...#{n} #{label}s processed"

has_module_ids = next args.module_id

limit_clause = args.limit and " limit #{args.limit}" or ""

versions_clause = if has_module_ids
  db.clause {
    module_id: db.list args.module_id
  }
else
  db.clause {
    "sha256 is null or size is null"
  }

rocks_clause = if has_module_ids
  db.clause {
    { "version_id in (select id from versions where module_id in ?)", db.list args.module_id }
  }
else
  db.clause {
    "sha256 is null or size is null"
  }

unless args.rocks_only
  print "backfilling versions..."
  versions = Versions\select "WHERE ?#{limit_clause}", versions_clause, fields: "id, rockspec_key"
  backfill "version", versions, (r) -> r.rockspec_key

unless args.versions_only
  print "backfilling rocks..."
  rocks = Rocks\select "WHERE ?#{limit_clause}", rocks_clause, fields: "id, rock_key"
  backfill "rock", rocks, (r) -> r.rock_key

io.stderr\write args.confirm and "Done.\n" or "Dry run; pass --confirm to apply.\n"
