
db = require "lapis.db"
bcrypt = require "bcrypt"

import Model from require "lapis.db.model"
import slugify, underscore from require "lapis.util"

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
    user = Users\find { :username }
    if user and bcrypt.verify password, user.encrypted_password
      user
    else
      nil, "Incorrect username or password"

  @read_session: (r) =>
    if user_session = r.session.user
      user = @find user_session.id
      if user\salt! == user_session.key
        user

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29


class Rocks extends Model
  @timestamp: true

  @create: (rockspec_text, user) =>
    fn = loadstring rockspec_text, rock
    return nil, "Failed to parse rockspec" unless fn
    rock = {}
    setfenv fn, rock
    return nil, "Failed to eval rockspec" unless pcall(fn)
    description = rock.description or {}

    Model.create @, {
      user_id: user.id
      name: rock.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }

    -- create the first version

class Versions
  @timestamp: true

  @create: (rock, spec) ->


{ :Users, :Rocks }
