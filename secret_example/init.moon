->
  secret "testsecret"
  session_name "moonrocks"

  github_client_id "xxx"
  github_client_secret "xxxxxx"

  -- File audit system (rocks-audit GitHub Actions integration)
  audit_hmac_secret "shared-secret-for-hmac-signing"
  audit_github_token "github_pat_xxxxxxxxxxxxxxxxxxxx" -- fine-grained PAT, rocks-audit repo only, Actions: read and write
  audit_github_repo "owner/rocks-audit" -- GitHub repo with audit workflow
  audit_callback_url "https://luarocks.org/api/audit-callback"
