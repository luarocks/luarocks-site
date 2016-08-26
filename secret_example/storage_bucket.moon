import CloudStorage from require "cloud_storage.google"

config = require"lapis.config".get!

oauth_stub = {
  client_email: "dad@streak.club"
  get_access_token: => "test-access-token"
  sign_string: (str) => "test-signature"
}

storage = CloudStorage(oauth_stub, "ACCOUNT")
storage._put = => 200, "ok"
storage\bucket config.bucket_name
