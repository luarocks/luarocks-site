

argparse = require "argparse"

parser = argparse "delete_user.moon", "Delete a user from the system"

parser\argument("user_id", "ID of the user to delete")\args "+"

parser\flag "--confirm", "Confirm deletion"
parser\flag "--api-key", "Lookup user by API key instead of user ID"

args = parser\parse [v for _, v in ipairs _G.arg]

import Users, ApiKeys from require "models"

db = require "lapis.db"

import to_json from require "lapis.util"

db.query "BEGIN"

count = 0
total = 0

for user_id in *args.user_id
  total += 1

  user = if args.api_key
    api_key = ApiKeys\find key: user_id
    unless api_key
      io.stderr\write "No API key: #{user_id}\n"
      continue
    api_key\get_user!
  else
    Users\find user_id

  unless user
    io.stderr\write "No user with ID #{user_id}\n"
    continue

  print to_json user\data_export!

  if next user\get_modules!
    io.stderr\write "User has modules, skipping delete\n"
    continue

  if user\delete!
    count += 1
    io.stderr\write "Deleted user #{user.username}\n"

io.stderr\write "Deleted #{count} of #{total} users\n"

if args.confirm
  db.query "COMMIT"
else
  io.stderr\write "Rolling back, use --confirm to commit deletion\n"

