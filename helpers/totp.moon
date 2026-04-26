-- HOTP/TOTP (RFC 6238) implementation, compatible with Google Authenticator, 1Password, Authy, etc.

import to_base32, from_base32 from require "basexx"
import hmac_sha1 from require "lapis.util.encoding"
rand = require "openssl.rand"
bit = require "bit"

SECRET_BITS = 80 -- must be divisible by 8

SCRATCHCODES = 5
SCRATCHCODE_LENGTH = 8
BYTES_PER_SCRATCHCODE = 4

DIGITS_POWER = { 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000 }
NUM_DIGITS = 6

SHA1_DIGEST_LENGTH = 20

generate_secret = ->
  to_base32 rand.bytes SECRET_BITS / 8

generate_scratchcodes = (num_codes = SCRATCHCODES, num_digits = SCRATCHCODE_LENGTH) ->
  codes = {}
  for i=1,num_codes
    scratch = 0
    success = false
    while not success
      buf = rand.bytes BYTES_PER_SCRATCHCODE

      scratch = 0
      for j=1,BYTES_PER_SCRATCHCODE
        scratch = 256 * scratch + string.byte buf, j

      scratch = bit.band scratch, 0x7FFFFFFF
      modulus = DIGITS_POWER[num_digits]
      scratch = scratch % modulus
      success = scratch >= modulus / 10
    codes[i] = tostring scratch

  codes

time_interval = ->
  math.floor os.time() / 30

encode_challenge = (tm) ->
  challenge = {}
  for i=8,1,-1
    challenge[i] = tm % 256
    tm = bit.rshift(tm, 8)
  string.char unpack challenge

generate_code = (key, tm = time_interval(), num_digits = NUM_DIGITS) ->
  challenge = encode_challenge tm
  secret = from_base32 key

  hash = hmac_sha1 secret, challenge
  offset = bit.band string.byte(hash, SHA1_DIGEST_LENGTH), 0xF

  truncatedHash = 0
  for i=1,4
    truncatedHash = bit.lshift truncatedHash, 8
    truncatedHash = bit.bor truncatedHash, string.byte(hash, offset + i)

  truncatedHash = bit.band truncatedHash, 0x7FFFFFFF
  truncatedHash = truncatedHash % DIGITS_POWER[num_digits]

  result = tostring truncatedHash
  while string.len(result) < num_digits
    result = "0" .. result
  result

check_code = (key, code, window = 2, num_digits = NUM_DIGITS) ->
  return false unless code
  code = tostring code
  tm = time_interval!
  for i=0,window
    expected = generate_code key, tm - i, num_digits
    if expected == code
      return true
  false

-- otpauth:// URL for authenticator apps. Order of params matters for some
-- clients (Windows Phone Authenticator) — don't reorder.
get_url = (secret, label, issuer = "luarocks.org") ->
  import escape from require "lapis.util"
  label = escape "#{label}@#{issuer}"
  "otpauth://totp/#{label}?secret=#{escape secret}&issuer=#{escape issuer}"

{ :generate_secret, :generate_scratchcodes,
  :encode_challenge, :generate_code, :get_url
  :check_code, :time_interval }
