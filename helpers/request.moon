config = require("lapis.config").get!

import Request from require "lapis.application"

class R extends Request
  @support: {
    default_url_params: =>
      if config.enable_https
        {
          host: config.host
          port: config.ssl_port
          scheme: "https"
        }
      else
        {
          host: config.host
          port: config.port
          scheme: "http"
        }
  }
