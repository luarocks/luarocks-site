
import Model, enum from require "lapis.db.model"
import generate_key, generate_uuid from require "helpers.models"
import slugify from require "lapis.util"

date = require "date"

db = require "lapis.db"

BCRYPT_ROUNDS = 9

bcrypt = require "bcrypt"
bit = require "bit"

import strip_non_ascii from require "helpers.strings"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE users (
--   id integer NOT NULL,
--   username character varying(255) NOT NULL,
--   encrypted_password character varying(255),
--   email character varying(255) NOT NULL,
--   slug character varying(255) NOT NULL,
--   flags integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   following_count integer DEFAULT 0 NOT NULL,
--   modules_count integer DEFAULT 0 NOT NULL,
--   last_active_at timestamp without time zone,
--   followers_count integer DEFAULT 0 NOT NULL,
--   display_name character varying(255),
--   stared_count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY users
--   ADD CONSTRAINT users_pkey PRIMARY KEY (id);
-- CREATE INDEX users_flags_idx ON users USING btree (flags);
-- CREATE UNIQUE INDEX users_lower_email_idx ON users USING btree (lower((email)::text));
-- CREATE UNIQUE INDEX users_lower_username_idx ON users USING btree (lower((username)::text));
-- CREATE UNIQUE INDEX users_slug_idx ON users USING btree (slug);
-- CREATE INDEX users_username_idx ON users USING gin (username public.gin_trgm_ops);
--
class Users extends Model
  @timestamp: true

  -- this is for a bitset, so only bit values should be used
  @flags: enum {
    "admin": 1
    "suspended": 2
    "spam": 4
  }

  @relations: {
    {"api_keys", has_many: "ApiKeys", where: { revoked: false }}
    {"revoked_api_keys", has_many: "ApiKeys", where: { revoked: true }}
    {"modules", has_many: "Modules", order: "created_at desc"}
    {"github_accounts", has_many: "GithubAccounts", order: "updated_at desc"}
    {"follows", has_many: "Followings", key: "source_user_id"}
  }

  @create: (username, password, email, display_name) =>
    encrypted_password = nil

    if password
      encrypted_password = bcrypt.digest password, BCRYPT_ROUNDS

    stripped = strip_non_ascii username
    return nil, "username must be ascii only" unless stripped == username

    slug = slugify username

    if @check_unique_constraint "username", username
      return nil, "Username already taken"

    if @check_unique_constraint "slug", slug
      return nil, "Username already taken"

    if @check_unique_constraint "email", email
      return nil, "Email already taken"

    super {
      :username, :encrypted_password, :email, :slug, :display_name
    }

  @login: (username, password) =>
    user = Users\find [db.raw "lower(username)"]: username\lower!
    user or= Users\find [db.raw "lower(email)"]: username\lower!

    if user and user\check_password password

      if user\password_is_outdated!
        user\update_password password

      user
    else
      nil, "Incorrect username or password"

  @read_session: (r) =>
    import UserSessions from require "models"
    user_session = r.session.user
    return unless user_session
    return unless user_session.sid

    user = @find user_session.id
    return unless user and user\salt! == user_session.key

    session = UserSessions\find {
      user_id: assert user.id
      id: assert user_session.sid
      revoked: false
    }

    return nil unless session

    user, session

  @search: (query) =>
    query = query\gsub "[%?]", ""

    @paginated [[
      where username % ?
      order by similarity(username, ?) desc
    ]], query, query, per_page: 50

  @generate_username: (username) =>
    if username == nil
      username = "username"

    uuid = generate_uuid()
    "#{username}-#{uuid\gsub("-", "")\sub 1, 10}"

  update_password: (pass, r) =>
    @update encrypted_password: bcrypt.digest pass, BCRYPT_ROUNDS
    if r
      if r.current_user_session
        r.current_user_session\revoke!
      @write_session r, type: "update_password"

  check_password: (pass) =>
    return false unless @encrypted_password
    encrypted = @encrypted_password\gsub "^%$2y%$", "$2b$"
    bcrypt.verify pass, encrypted

  generate_password_reset: =>
    @get_data!
    with token = generate_key 30
      @data\update { password_reset_token: token }

  url_key: (name) => @slug

  url_params: =>
    "user_profile", user: @slug

  write_session: (r, opts={}) =>
    import UserSessions from require "models"
    session = UserSessions\create_from_request r, @, {
      type: opts.type
    }

    r.session.user = {
      id: @id
      sid: session.id
      key: @salt!
    }

    session

  salt: =>
    if @encrypted_password
      @encrypted_password\sub 1, 29
    else
      "nopassword"

  find_modules: (...) =>
    import Modules from require "models"
    Modules\paginated [[
      where user_id = ?
      order by name asc
    ]], @id, ...

  has_flag: (flag) =>
    0 != bit.band @flags or 0, flag

  -- user\update_flags suspended: true, spam: false
  update_flags: (t) =>
    flags = @flags
    for field, enabled in pairs t
      val = @@flags\for_db field

      if enabled
        flags = bit.bor flags, val
      else
        flags = bit.band flags, bit.bnot(val)

    if flags != @flags
      @update { :flags }

  is_admin: => @has_flag @@flags.admin
  is_suspended: => @has_flag @@flags.suspended
  is_spam: => @has_flag @@flags.spam

  source_url: (r) => r\build_url "/manifests/#{@slug}"

  get_data: =>
    import UserData from require "models"
    @data or= UserData\find(@id) or UserData\create(@id)
    @data

  gravatar: (size) =>
    url = "https://www.gravatar.com/avatar/#{ngx.md5 @email}?d=identicon"
    url = url .. "&s=#{size}" if size
    url

  name_for_display: =>
    @display_name or @username

  delete: =>
    return unless super!
    -- all other related models are deleted in cascade

    import Modules from require "models"

    -- delete modules in app layer to trigger deleting sub-models
    for m in *Modules\select "where user_id = ?", @id
      m\delete!

    true

  find_follow: (object) =>
    return unless object
    import Followings from require "models"
    Followings\find {
      source_user_id: @id
      object_type: Followings\object_type_for_object object
      object_id: object.id
      type: Followings.types\for_db "subscription"
    }

  find_star: (object) =>
    return unless object
    import Followings from require "models"
    Followings\find {
      source_user_id: @id
      object_type: Followings\object_type_for_object object
      object_id: object.id
      type: Followings.types\for_db "bookmark"
    }

  get_unseen_notifications_count: =>
    return @unseen_notification_count if @unseen_notification_count

    import Notifications from require "models"
    res = unpack Notifications\select "
      where user_id = ? and not seen
    ", @id, fields: "sum(count)"
    @unseen_notification_count = res and res.sum or 0
    @unseen_notification_count

  count_downloads: =>
    res = unpack db.query "select sum(downloads) from modules where user_id = ?", @id
    res.sum or 0

  update_last_active: =>
    span = if @last_active_at
      date.diff(date(true), date(@last_active_at))\spanminutes!

    if not span or span > 15
      @update {
        last_active_at: db.raw"date_trunc('second', now() at time zone 'utc')"
      }, timestamp: false

  has_password: =>
    not not @encrypted_password

  github_handle: =>
    if github_account = unpack @get_github_accounts!
      return github_account.github_login

    -- fall back to the manually provided github handle
    @get_data!\github_handle!

  password_is_outdated: =>
    return false unless @encrypted_password

    -- old format string
    if @encrypted_password\match "^%$2y%$"
      return true

    -- rounds mismatch
    rounds_str = "%02d"\format BCRYPT_ROUNDS
    unless @encrypted_password\match "^%$..%$#{rounds_str}%$"
      return true

    false

  data_export: =>
    db.query [[
      SELECT
        u.*,
        (SELECT json_agg(api_keys) FROM api_keys WHERE user_id = u.id) AS api_keys,
        (SELECT json_agg(github_accounts) FROM github_accounts WHERE user_id = u.id) AS github_accounts,
        (SELECT json_agg(linked_modules) FROM linked_modules WHERE user_id = u.id) AS linked_modules,
        (SELECT json_agg(manifest_admins) FROM manifest_admins WHERE user_id = u.id) AS manifest_admins,
        (SELECT json_agg(notifications) FROM notifications WHERE user_id = u.id) AS notifications,
        (SELECT json_agg(user_activity_logs) FROM user_activity_logs WHERE user_id = u.id) AS user_activity_logs,
        (SELECT json_agg(user_data) FROM user_data WHERE user_id = u.id) AS user_data,
        (SELECT json_agg(user_server_logs) FROM user_server_logs WHERE user_id = u.id) AS user_server_logs,
        (SELECT json_agg(user_sessions) FROM user_sessions WHERE user_id = u.id) AS user_sessions,
        (SELECT json_agg(followings) FROM followings WHERE source_user_id = u.id) AS followings,
        (SELECT json_agg(row_to_json(m.*)::jsonb || jsonb_build_object('versions', (SELECT json_agg(v.*) FROM versions v WHERE v.module_id = m.id))) FROM modules m WHERE user_id = u.id) AS modules

      FROM users u
      WHERE u.id = ?
    ]], @id


