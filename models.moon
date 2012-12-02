
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

class Versions extends Model
  @timestamp: true

  @create: (rock, spec, rockspec_url, rock_url, arch="source") =>
    if @check_unique_constraint rock_id: rock.id, version_name: spec.version
      return nil, "This version is already uploaded"

    Model.create @, {
      rock_id: rock.id
      version_name: spec.version
      :arch, :rockspec_url, :rock_url
    }

class Rocks extends Model
  @timestamp: true

  -- spec: parsed rockspec
  @create: (spec, user) =>
    description = spec.description or {}

    if @check_unique_constraint user_id: user.id, name: spec.package
      return nil, "Rock already exists"

    Model.create @, {
      user_id: user.id
      name: spec.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }

{ :Users, :Rocks, :Versions }
