
import get_file_name, screenshot_path from require "spec.helpers.screenshots"
import parse_query_string, encode_query_string from require "lapis.util"

(options) ->
  busted = require "busted"
  handler = require("busted.outputHandlers.utfTerminal") options

  local spec_name

  busted.subscribe { "test", "start" }, (context) ->
    spec_name = get_file_name context

  busted.subscribe { "test", "end" }, ->
    spec_name = nil

  busted.subscribe { "lapis", "screenshot" }, (url, opts) ->
    assert spec_name, "no spec name set"

    import get_current_server from require "lapis.spec.server"
    server = get_current_server!

    if opts.get
      _, url_query = url\match "^(.-)%?(.*)$"
      get_params = url_query and parse_query_string(url_query) or {}
      for k,v in pairs opts.get
        get_params[k] = v

      url = url\gsub("(%?.*)$", "") .. "?" .. encode_query_string get_params

    host, path = url\match "^https?://([^/]*)(.*)$"

    headers = for k,v in pairs opts.headers or {}
      "--custom-header '#{k}' '#{v}'"

    if host
      table.insert headers, "--custom-header 'Host' '#{host}:#{server.app_port}'"
    else
      path = url

    full_url = "http://127.0.0.1:#{server.app_port}#{path}"

    headers = table.concat headers, " "

    cmd = "wkhtmltoimage -q #{headers} '#{full_url}' '#{screenshot_path(spec_name)}'"
    assert os.execute cmd

  handler
