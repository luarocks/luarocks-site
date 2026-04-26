
import Model from require "lapis.db.model"

import generate_scratchcodes from require "helpers.totp"

class TotpSecrets extends Model
  @primary_key: "user_id"
  @timestamp: true

  -- stores the TOTP secret and seeds 5 bcrypt-hashed scratchcodes
  @create_for: (user, secret) =>
    bcrypt = require "bcrypt"
    import TotpScratchcodes from require "models"

    -- note: this will cascade delete any existing scratchcodes
    if existing = @find user.id
      existing\delete!

    instance = @create {
      user_id: user.id
      :secret
    }

    return nil unless instance

    plaintext_codes = generate_scratchcodes!
    for code in *plaintext_codes
      TotpScratchcodes\create {
        user_id: user.id
        secret: bcrypt.digest code, 9
      }

    instance, plaintext_codes
