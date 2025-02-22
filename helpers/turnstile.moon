-- curl 'https://challenges.cloudflare.com/turnstile/v0/siteverify' --data 'secret=verysecret&response=<RESPONSE>'

http = require "lapis.http"
ltn12 = require "ltn12"
import from_json, encode_query_string from require "lapis.util"

verify_turnstile_response = (response, ip, idempotency_key=nil) ->
  secret_key = require("secret.turnstile").secret_key

  assert secret_key, "missing turnstile_secret_key"
  url = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  params = {
    secret: secret_key,
    response: response,
    remoteip: ip
    :idempotency_key
  }

  out = {}
  _, status = http.request {
    url: url
    method: "POST"
    sink: ltn12.sink.table out
    source: ltn12.source.string encode_query_string params
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    }
  }

  text = table.concat out
  res = from_json text
  res.success, res["error-codes"]

{:verify_turnstile_response}
