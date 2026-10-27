config = require("lapis.config").get!

db = require "lapis.db"
json = require "cjson"
types = require "lapis.validate.types"

import build_url, slugify from require "lapis.util"
import preload from require "lapis.db.model"
import McpServer from require "lapis.mcp.server"
import McpHttpRouter from require "lapis.mcp.http"
import Users, Modules, Versions, Manifests, ManifestModules, DownloadsDaily,
  McpGrants, UserActivityLogs from require "models"

-- the proxy in front of the app doesn't send X-Forwarded-Proto, which
-- lapis-mcp would otherwise derive the public URL from
PUBLIC_BASE_URL = if config.enable_https
  build_url { scheme: "https", host: config.host, port: config.ssl_port }

SUSPENDED = "This account is suspended or no longer exists"

-- timestamps are stored in UTC without a zone
utc = (time) -> time and "#{(time\gsub " ", "T")}Z"

-- cjson encodes an empty table as an object
array = (t) -> setmetatable t, json.array_mt

-- the JSON schema conversion can't express a length limit, so long input is
-- cut short instead of rejected
text = types.string / (s) -> s\sub 1, 256

module_name = text\describe "Module name, for example lpeg"
module_user = text\describe("Username of the module's owner. Without it the module in the root manifest is used")\is_optional!

find_module = (name, username) ->
  name = name\lower!

  mod = if username
    if user = Users\find slug: slugify username
      Modules\find user_id: user.id, :name
  else
    if mm = ManifestModules\find manifest_id: Manifests\root!.id, module_name: name
      mm\get_module!

  return nil, "Module not found: #{name}" unless mod
  mod

class LuarocksMcp extends McpServer
  @server_name: "luarocks"

  module_info: (mod, extra) =>
    info = {
      name: mod.name
      user: mod\get_user!.slug
      summary: mod.summary
      downloads: mod.downloads
      url: @req\build_url @req\url_for mod
    }

    if extra
      for k, v in pairs extra
        info[k] = v

    info

  @add_tool {
    name: "me"
    description: "Get the luarocks.org account this connection is logged in as"
    annotations: { readOnlyHint: true }
    inputSchema: { type: "object", properties: {} }
  }, (params) =>
    return nil, SUSPENDED unless @user

    {
      id: @user.id
      username: @user.username
      display_name: @user.display_name
      profile_url: @req\build_url @req\url_for @user
      modules_count: @user.modules_count
      created_at: utc @user.created_at
    }

  @add_tool {
    name: "search_modules"
    description: "Search modules in the root manifest by name and description"
    annotations: { readOnlyHint: true }
    inputShape: types.shape {
      query: text\describe "Search terms"
    }
  }, (params) =>
    return nil, SUSPENDED unless @user

    results = [mod for mod in *Modules\search(params.query, { Manifests\root!.id })[,20]]
    preload results, "user"
    array [@module_info mod for mod in *results]

  @add_tool {
    name: "get_module"
    description: "Get a module's details and its versions, newest first"
    annotations: { readOnlyHint: true }
    inputShape: types.shape {
      module: module_name
      user: module_user
    }
  }, (params) =>
    return nil, SUSPENDED unless @user
    mod, err = find_module params.module, params.user
    return nil, err unless mod

    @module_info mod, {
      display_name: mod.display_name
      description: mod.description
      license: mod.license
      homepage: mod.homepage
      labels: mod.labels and array mod.labels
      followers: mod.followers_count
      stars: mod.stars_count
      created_at: utc mod.created_at
      versions: array for v in *Versions\sort_versions mod\get_versions!
        {
          version: v.version_name
          downloads: v.downloads
          development: v.development
          archived: v.archived
          created_at: utc v.created_at
        }
    }

  @add_tool {
    name: "get_module_version"
    description: "Get one version of a module: its dependencies, rockspec URL and rock files"
    annotations: { readOnlyHint: true }
    inputShape: types.shape {
      module: module_name
      user: module_user
      version: text\describe "Version name, for example 1.0.2-1"
    }
  }, (params) =>
    return nil, SUSPENDED unless @user

    mod, err = find_module params.module, params.user
    return nil, err unless mod

    version = Versions\find module_id: mod.id, version_name: params.version\lower!
    return nil, "Version not found: #{params.version}" unless version

    {
      module: @module_info mod
      version: version.version_name
      lua_version: version.lua_version
      development: version.development
      archived: version.archived
      downloads: version.downloads
      rockspec_url: (version\url!)
      source_url: version.source_url
      created_at: utc version.created_at
      dependencies: array [dep.dependency for dep in *version\get_dependencies!]
      rocks: array for rock in *version\get_rocks!
        {
          arch: rock.arch
          downloads: rock.downloads
          url: rock\url!
          size: rock.size
        }
      url: @req\build_url @req\url_for version
    }

  @add_tool {
    name: "my_modules"
    description: "List the modules owned by the account this connection is logged in as"
    annotations: { readOnlyHint: true }
    inputSchema: { type: "object", properties: {} }
  }, (params) =>
    return nil, SUSPENDED unless @user

    mods = Modules\select "where user_id = ? order by name asc", @user.id
    preload mods, "current_version"
    for mod in *mods
      mod.user = @user

    array [@module_info mod, {
      current_version: mod.current_version and mod.current_version.version_name
    } for mod in *mods]

  @add_tool {
    name: "get_module_downloads"
    description: "Get download counts for a module: daily totals for the last days, and totals per version. Days start at midnight UTC-7"
    annotations: { readOnlyHint: true }
    inputShape: types.shape {
      module: module_name
      user: module_user
      days: types.number\describe("Number of days of daily counts, 30 when not given, at most 365")\is_optional!
    }
  }, (params) =>
    return nil, SUSPENDED unless @user

    mod, err = find_module params.module, params.user
    return nil, err unless mod

    days = math.min 365, math.max 1, math.floor params.days or 30
    since = DownloadsDaily\date 1 - days

    -- downloads_daily has no row for a day without downloads
    daily = db.query "
      select day::date as date, coalesce(sum(downloads_daily.count), 0) as count
      from generate_series(?::date, ?::date, '1 day') as day
      left join downloads_daily on downloads_daily.date = day::date
        and downloads_daily.version_id in (select id from versions where module_id = ?)
      group by day order by day asc
    ", since, DownloadsDaily\date!, mod.id

    in_period = {}
    for row in *db.query "
      select version_id, sum(count) as count from downloads_daily
      where date >= ? and version_id in (select id from versions where module_id = ?)
      group by version_id
    ", since, mod.id
      in_period[row.version_id] = row.count

    @module_info mod, {
      followers: mod.followers_count
      stars: mod.stars_count
      since: since
      daily: array [{date: row.date, downloads: row.count} for row in *daily]
      versions: array for v in *Versions\sort_versions mod\get_versions!
        {
          version: v.version_name
          downloads: v.downloads
          downloads_in_period: in_period[v.id] or 0
        }
    }

router = McpHttpRouter!

router\mount "/mcp", LuarocksMcp, {
  oauth: {
    grants: McpGrants
    allow_any_client: true
    public_base_url: PUBLIC_BASE_URL
    cache: ngx and ngx.shared and ngx.shared.mcp_clients

    -- the test server can't reach the network
    http: config.mcp_client_metadata_http and require config.mcp_client_metadata_http

    current_user: (route) -> route.current_user
    login_url: (route, return_to) -> route\url_for "user_login", nil, :return_to
    render_consent: (route, consent) ->
      route.consent = consent
      route.mcp_tools = LuarocksMcp!\get_enabled_tools!
      route.title = "Connect to LuaRocks"
      render: "mcp_consent"

    grant_created: (route, grant) ->
      UserActivityLogs\create_from_request route, {
        user_id: grant.user_id
        action: "account.create_mcp_grant"
        source: "web"
        data: {
          client_id: grant.client_id
          client_name: grant.client_name
        }
      }
  }

  load_session: (req, server) ->
    server.req = req
    user = server.auth.grant\get_user!
    server.user = user unless user and user\is_suspended!
}

router\application!
