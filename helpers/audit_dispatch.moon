
http = require "lapis.http"
ltn12 = require "ltn12"
import to_json, from_json from require "lapis.util"

config = require("lapis.config").get!

-- Dispatch a file audit to the GitHub Actions workflow
-- Returns true on success, or nil + error message
dispatch_audit = (file_audit) ->
  github_token = config.audit_github_token
  github_repo = config.audit_github_repo

  unless github_token
    return nil, "missing audit_github_token in config"

  unless github_repo
    return nil, "missing audit_github_repo in config"

  inputs, err = file_audit\get_dispatch_payload!
  return nil, err unless inputs

  -- GitHub API endpoint for workflow dispatch
  -- https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches
  url = "https://api.github.com/repos/#{github_repo}/actions/workflows/audit.yml/dispatches"

  body = to_json {
    ref: "master"
    :inputs
  }

  out = {}
  _, status = http.request {
    :url
    method: "POST"
    sink: ltn12.sink.table out
    source: ltn12.source.string body
    headers: {
      "Accept": "application/vnd.github+json"
      "Authorization": "Bearer #{github_token}"
      "X-GitHub-Api-Version": "2022-11-28"
      "Content-Type": "application/json"
      "User-Agent": "LuaRocks.org"
    }
  }

  response_text = table.concat out
  response = if response_text and response_text != ""
    from_json response_text

  status, response or response_text

{:dispatch_audit}
