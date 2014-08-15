
import Model from require "lapis.db.model"
import generate_key from require "helpers.models"
import slugify from require "lapis.util"

db = require "lapis.db"

bcrypt = require "bcrypt"

class Users extends Model
  @timestamp: true

  @create: (username, password, email) =>
    encrypted_password = bcrypt.digest password, bcrypt.salt 5
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

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29

  all_modules: (...) =>
    import get_all_pages from require "helpers.models"
    get_all_pages @find_modules ...

  find_modules: (...) =>
    import Modules from require "models"
    Modules\paginated [[
      where user_id = ?
      order by name asc
    ]], @id, ...

  is_admin: => @flags == 1

  source_url: (r) => r\build_url "/manifests/#{@slug}"

  get_data: =>
    return if @data
    import UserData from require "models"
    @data = UserData\find(@id) or UserData\create(@id)
    @data

  gravatar: (size) =>
    url = "https://www.gravatar.com/avatar/#{ngx.md5 @email}?d=identicon"
    url = url .. "&s=#{size}" if size
    url

  find_github_accounts: =>
    import GithubAccounts from require "models"
    GithubAccounts\select "where user_id = ? order by updated_at desc", @id

  delete: =>
    import
      Modules
      UserData
      ApiKeys
      GithubAccounts
      ManifestAdmins
      LinkedModules from require "models"

    super!

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

