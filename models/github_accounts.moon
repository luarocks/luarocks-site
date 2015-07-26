db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE github_accounts (
--   user_id integer NOT NULL,
--   github_login text NOT NULL,
--   github_user_id integer DEFAULT 0 NOT NULL,
--   access_token text NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY github_accounts
--   ADD CONSTRAINT github_accounts_pkey PRIMARY KEY (user_id, github_user_id);
--
class GithubAccounts extends Model
  @primary_key: {"user_id", "github_user_id"}
  @timestamp: true

  orgs: =>
    github = require "helpers.github"
    github\orgs @github_login, @access_token

  modules_for_account: (user="luarocks") =>
    import Versions, Modules, Users from require "models"

    logins = { @github_login }
    for org in *@orgs!
      table.insert logins, org.login

    patterns = for login in *logins
      table.concat {
        "^(https?|git)://github\\.com/#{login}/"
        "^https?://cloud\\.github\\.com/downloads/#{login}/"
        "^https?://raw\\.github\\.com/#{login}/"
        "^https?://#{login}\\.github\\.(io|com)/"
      }, "|"

    patt = table.concat(patterns, "|")
    repo_user = Users\find [db.raw("lower(username)")]: user\lower!

    module_id_set = {}

    module_ids = Versions\select [[
      where source_url ~ ?
      and module_id in (select id from modules where user_id = ?)
    ]], patt, repo_user.id,
      fields: "distinct module_id"

    for m in *module_ids
      module_id_set[m.module_id] = true

    module_ids = Modules\select [[
      where homepage ~ ?
      and id in (select id from modules where user_id = ?)
    ]], patt, repo_user.id

    for m in *module_ids
      module_id_set[m.id] = true

    Modules\find_all [key for key in pairs module_id_set]

