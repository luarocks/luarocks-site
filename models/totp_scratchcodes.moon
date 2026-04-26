
import Model from require "lapis.db.model"

class TotpScratchcodes extends Model
  @for_user: (user) =>
    @select "where user_id = ?", user.id

  -- Linear scan over the user's bcrypt-hashed scratchcodes and claim one by
  -- deleting it
  @verify_and_consume: (user, code) =>
    return false unless code and code != ""
    bcrypt = require "bcrypt"
    code = tostring code

    for row in *@for_user user
      if bcrypt.verify code, row.secret
        return true if row\delete!
        return false

    false
