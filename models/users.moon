
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"
import slugify from require "lapis.util"

date = require "date"

db = require "lapis.db"

bcrypt = require "bcrypt"

import strip_non_ascii from require "helpers.strings"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE users (
--   id integer NOT NULL,
--   username character varying(255) NOT NULL,
--   encrypted_password character varying(255) NOT NULL,
--   email character varying(255) NOT NULL,
--   slug character varying(255) NOT NULL,
--   flags integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   following_count integer DEFAULT 0 NOT NULL,
--   modules_count integer DEFAULT 0 NOT NULL,
--   last_active_at timestamp without time zone
-- );
-- ALTER TABLE ONLY users
--   ADD CONSTRAINT users_pkey PRIMARY KEY (id);
-- CREATE INDEX users_flags_idx ON users USING btree (flags);
-- CREATE UNIQUE INDEX users_lower_email_idx ON users USING btree (lower((email)::text));
-- CREATE UNIQUE INDEX users_lower_username_idx ON users USING btree (lower((username)::text));
-- CREATE UNIQUE INDEX users_slug_idx ON users USING btree (slug);
-- CREATE INDEX users_username_idx ON users USING gin (username gin_trgm_ops);
--
class Users extends Model
  @timestamp: true

  @relations: {
    {"api_keys", has_many: "ApiKeys"}
    {"modules", has_many: "Modules"}
  }

  @create: (username, password, email) =>
    encrypted_password = bcrypt.digest password, bcrypt.salt 5

    stripped = strip_non_ascii username
    return nil, "username must be ascii only" unless stripped == username

    slug = slugify username

    if @check_unique_constraint "username", username
      return nil, "Username already taken"

    if @check_unique_constraint "slug", slug
      return nil, "Username already taken"

    if @check_unique_constraint "email", email
      return nil, "Email already taken"

    Model.create @, {
      :username, :encrypted_password, :email, :slug
    }

  @login: (username, password) =>
    user = Users\find [db.raw "lower(username)"]: username\lower!
    user or= Users\find [db.raw "lower(email)"]: username\lower!

    if user and user\check_password password
      user
    else
      nil, "Incorrect username or password"

  @read_session: (r) =>
    if user_session = r.session.user
      user = @find user_session.id
      if user and user\salt! == user_session.key
        user

  @search: (query) =>
    query = query\gsub "[%?]", ""

    @paginated [[
      where username % ?
      order by similarity(username, ?) desc
    ]], query, query, per_page: 50

  update_password: (pass, r) =>
    @update encrypted_password: bcrypt.digest pass, bcrypt.salt 5
    @write_session r if r

  check_password: (pass) =>
    bcrypt.verify pass, @encrypted_password

  generate_password_reset: =>
    @get_data!
    with token = generate_key 30
      @data\update { password_reset_token: token }

  url_key: (name) => @slug

  url_params: =>
    "user_profile", user: @slug

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29

  find_modules: (...) =>
    import Modules from require "models"
    Modules\paginated [[
      where user_id = ?
      order by name asc
    ]], @id, ...

  is_admin: => @flags == 1

  source_url: (r) => r\build_url "/manifests/#{@slug}"

  get_data: =>
    import UserData from require "models"
    @data or= UserData\find(@id) or UserData\create(@id)
    @data

  gravatar: (size) =>
    url = "https://www.gravatar.com/avatar/#{ngx.md5 @email}?d=identicon"
    url = url .. "&s=#{size}" if size
    url

  find_github_accounts: =>
    import GithubAccounts from require "models"
    GithubAccounts\select "where user_id = ? order by updated_at desc", @id

  name_for_display: =>
    @username

  delete: =>
    return unless super!

    import
      Modules
      UserData
      ApiKeys
      GithubAccounts
      ManifestAdmins
      LinkedModules from require "models"

    -- delete modules
    for m in *Modules\select "where user_id = ?", @id
      m\delete!

    -- delete user data
    @get_data!\delete!

    -- delete api keys
    db.delete ApiKeys\table_name!, user_id: @id

    -- delete github accounts
    db.delete GithubAccounts\table_name!, user_id: @id

    -- delete manifest admins
    db.delete ManifestAdmins\table_name!, user_id: @id

    -- delete linked modules
    for link in *LinkedModules\select "where user_id = ?", @id
      link\delete!

    true

  follows: (object) =>
    return unless object
    import Followings from require "models"
    Followings\find {
      source_user_id: @id
      object_type: Followings\object_type_for_object object
      object_id: object.id
    }

  endorses: (object) =>
    return unless object
    import Endorsements from require "models"
    Endorsements\find {
      source_user_id: @id
      --object_type: Endorsements\object_type_for_object object
      object_id: object.id
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
      date.diff(date(true), date(@last_active_at))\spandays!

    if not span or span > 0.5
      @update {
        last_active_at: db.raw"date_trunc('second', now() at time zone 'utc')"
      }, timestamp: false

