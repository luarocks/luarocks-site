
db = require "lapis.db" 
import Model from require "lapis.db.model"

import concat from table 
import safe_insert from require "helpers.models"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE modules (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   name character varying(255) NOT NULL,
--   downloads integer DEFAULT 0 NOT NULL,
--   current_version_id integer NOT NULL,
--   summary character varying(255),
--   description text,
--   license character varying(255),
--   homepage character varying(255),
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   display_name character varying(255),
--   endorsements_count integer DEFAULT 0 NOT NULL,
--   has_dev_version boolean DEFAULT false NOT NULL,
--   followers_count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY modules
--   ADD CONSTRAINT modules_pkey PRIMARY KEY (id);
-- CREATE INDEX module_search_idx ON modules USING gin (to_tsvector('english'::regconfig, (((((COALESCE(display_name, name))::text || ' '::text) || (COALESCE(summary, ''::character varying))::text) || ' '::text) || COALESCE(description, ''::text))));
-- CREATE INDEX modules_downloads_idx ON modules USING btree (downloads);
-- CREATE INDEX modules_name_idx ON modules USING btree (name);
-- CREATE INDEX modules_name_search_idx ON modules USING gin ((COALESCE(display_name, name)) gin_trgm_ops);
-- CREATE INDEX modules_user_id_idx ON modules USING btree (user_id);
-- CREATE UNIQUE INDEX modules_user_id_name_idx ON modules USING btree (user_id, name);
--
class Modules extends Model
  @timestamp: true

  @search_index: [[
    to_tsvector('english', coalesce(display_name, name) || ' ' || coalesce(summary, '') || ' ' || coalesce(description, ''))
  ]]

  @name_search_index: [[
    coalesce(display_name, name)
  ]]

  @relations: {
    {"user", belongs_to: "Users"}
    {"versions", has_many: "Versions", order: "created_at desc"}
  }

  -- spec: parsed rockspec
  @create: (spec, user) =>
    description = spec.description or {}
    name = spec.package\lower!

    mod = safe_insert @, {
      :name
      user_id: user.id
      display_name: if name != spec.package then spec.package

      current_version_id: -1

      summary: description.summary
      description: description.detailed
      license: description.license
      homepage: description.homepage
    }, {
      :name
      user_id: user.id
    }

    if mod
      user\update {
        modules_count: db.raw "modules_count + 1"
      }, timestamp: false

    mod

  @search: (query, manifest_ids) =>
    tsquery = query\gsub [==[[?'"!@#$%%^&*%(%)_%-\|+/+.>,<:*]]==], " "
    -- make them all prefix matches
    tsquery = table.concat ["#{word}:*" for word in tsquery\gmatch "[^%s]+"], " & "
    query = query\gsub("[%?]", "")\lower!

    tsquery = db.interpolate_query "to_tsquery('english', ?)", tsquery
    rank = "ts_rank_cd(#{@search_index}, #{tsquery})"

    clause = if manifest_ids
      ids = table.concat [tonumber id for id in *manifest_ids], ", "
      "and exists(select 1 from manifest_modules where manifest_id in (#{ids}) and module_id = modules.id)"

    matches = @select "
      where (lower(name) = ? or (display_name is not null and lower(display_name) = ?))
      #{clause or ""}
      order by downloads desc limit 5
    ", query, query

    exclude = next(matches) and db.interpolate_query "and id not in ?",
      db.list [m.id for m in *matches]

    fuzzy_matches = @select "
      where #{@search_index} @@ #{tsquery}
        #{exclude or ""}
        #{clause or ""}
      order by #{rank} desc
      limit 50
    "

    for m in *fuzzy_matches
      table.insert matches, m

    matches

  url_key: (name) => @name

  url_params: =>
    "module", user: @get_user!, module: @

  name_for_display: =>
    @display_name or @name

  format_homepage_url: =>
    return if not @homepage or @homepage == ""

    unless @homepage\match "%w+://"
      return "http://" .. @homepage

    @homepage

  allowed_to_edit: (user) =>
    user and (user.id == @user_id or user\is_admin!)

  get_labels: =>
    labels = {}
    import LabelsModules from require "models"
    lm = LabelsModules\select "where module_id = ?", @id
    [l\get_label! for l in *lm]

  get_manifests: =>
    unless @manifests
      import Manifests from require "models"

      @manifests = Manifests\select "
        where id in
          (select manifest_id from manifest_modules where module_id = ?)
        order by name asc
      ", @id

    @manifests

  -- gets the first non-root manifest
  get_primary_manifest: =>
    for m in *@get_manifests!
      if m.name == "root"
        return m

  in_root_manifest: =>
    for m in *@get_manifests!
      if m.name == "root"
        return m

    false

  count_versions: =>
    res = db.query "select count(*) as c from versions where module_id = ?", @id
    res[1].c

  delete: =>
    import Versions, ManifestModules, LinkedModules from require "models"

    if super!
      -- Remove module from manifests
      db.delete ManifestModules\table_name!, module_id: @id

      -- Remove versions
      versions = Versions\select "where module_id = ? ", @id
      for v in *versions
        v\delete!

      -- remove the link
      for link in *LinkedModules\select "where module_id = ?", @id
        link\delete!

      @get_user!\update {
        modules_count: db.raw "modules_count - 1"
      }, timestamp: false

      true

  -- copies module/versions/rocks to user
  copy_to_user: (user, take_root=false) =>
    return if user.id == @user_id

    bucket = require "storage_bucket"
    import Versions, Rocks, LinkedModules from require "models"

    module_keys = {
      "name", "display_name", "downloads", "summary", "description", "license",
      "homepage"
    }

    version_keys = {
      "version_name", "display_version_name", "rockspec_fname", "downloads",
      "rockspec_downloads", "lua_version", "source_url", "development"
    }

    rock_keys = {
      "arch", "downloads", "rock_fname"
    }

    new_module = Modules\find user_id: user.id, name: @name
    unless new_module
      params = { k, @[k] for k in *module_keys }
      params.user_id = user.id
      params.current_version_id = -1
      new_module = Model.create Modules, params

      user\update {
        modules_count: db.raw "modules_count + 1"
      }, timestamp: false

    versions = @get_versions!
    for version in *versions
      new_version = Versions\find {
        module_id: new_module.id
        version_name: version.version_name
      }

      unless new_version
        params = { k, version[k] for k in *version_keys }
        params.module_id = new_module.id
        params.rockspec_key = "#{user.id}/#{version.rockspec_fname}"

        rockspec_text = bucket\get_file version.rockspec_key
        bucket\put_file_string rockspec_text, {
          key: params.rockspec_key
          mimetype: "text/x-rockspec"
        }

        new_version = Model.create Versions, params

      rocks = version\get_rocks!
      for rock in *rocks
        new_rock = Rocks\find {
          version_id: new_version.id
          arch: rock.arch
        }

        unless new_rock
          params = { k, rock[k] for k in *rock_keys }
          params.version_id = new_version.id
          params.rock_key = "#{user.id}/#{rock.rock_fname}"

          rock_bin = bucket\get_file rock.rock_key
          bucket\put_file_string rock_bin, {
            key: params.rock_key
            mimetype: "application/x-rock"
          }

          new_rock = Model.create Rocks, params

    LinkedModules\find_or_create @id, user.id

    if take_root
      import ManifestModules, Manifests from require "models"
      root = Manifests\root!

      if mm = ManifestModules\find module_id: @id, manifest_id: root.id
        mm\delete!
        assert ManifestModules\create root, new_module

    new_module

  purge_manifests: =>
    for m in *@get_manifests fields: "id"
      m\purge!

  endorse: (user) =>
    import Endorsements from require "models"
    Endorsements\endorse user, @

  endorsement: (user) =>
    return unless user
    import Endorsements from require "models"
    Endorsements\find user_id: user.id, module_id: @id

  update_has_dev_version: =>
    @update has_dev_version: db.raw [[exists(
      select 1 from versions where module_id = modules.id
      and development
    )]]

  short_license: =>
    return nil if not @license or @license\match "^%s*$"
    @license\gsub("<http.->", "")\match "^%s*(.-)%s*$"

  find_depended_on: =>
    import Modules, Users from require "models"

    modules = Modules\select "
      where id in
        (select distinct module_id from versions where id in
          (select version_id from dependencies where dependency_name = ?))
      order by name asc
    ", @name

    Users\include_in modules, "user_id"
    modules


