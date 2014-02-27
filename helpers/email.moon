
ltn12 = require "ltn12"

http = require "lapis.nginx.http"
import encode_query_string from require "lapis.util"
import encode_base64 from require "lapis.util.encoding"

import concat from table

local key, domain, sender
pcall ->
  {:key, :domain, :sender} = require "secret.email"

send_email = if key
  (to, subject, body, opts={}) ->
    out = {}
    res = http.request {
      url: "https://api.mailgun.net/v2/#{domain}/messages"
      source: ltn12.source.string encode_query_string {
        to: to
        from: sender
        subject: subject
        [opts.html and "html" or "text"]: body
      }
      headers: {
        "Content-type": "application/x-www-form-urlencoded"
        "Authorization": "Basic " .. encode_base64 key
      }
      sink: ltn12.sink.table out
    }

    concat(out), res
else
  ->


{ :send_email }
