
lapis = require "lapis"

import
  assert_csrf
  require_login
  from require "helpers.apps"

class MoonrocksGithub extends lapis.Application
  [github_auth: "/github/auth"]: require_login =>
    @html -> pre @params

