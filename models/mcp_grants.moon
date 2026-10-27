db = require "lapis.db"
import OauthGrantModel from require "lapis.mcp.oauth.grant_model"

NOW = "(now() at time zone 'utc')"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE mcp_grants (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   client_id text NOT NULL,
--   client_name text NOT NULL,
--   redirect_uri text NOT NULL,
--   code_challenge text NOT NULL,
--   resource text NOT NULL,
--   code_hash text,
--   code_expires_at timestamp without time zone,
--   access_hash text,
--   access_expires_at timestamp without time zone,
--   last_used_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY mcp_grants
--   ADD CONSTRAINT mcp_grants_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX mcp_grants_access_hash_idx ON mcp_grants USING btree (access_hash) WHERE (access_hash IS NOT NULL);
-- CREATE UNIQUE INDEX mcp_grants_code_hash_idx ON mcp_grants USING btree (code_hash) WHERE (code_hash IS NOT NULL);
-- CREATE INDEX mcp_grants_user_id_idx ON mcp_grants USING btree (user_id);
-- ALTER TABLE ONLY mcp_grants
--   ADD CONSTRAINT mcp_grants_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
--
class McpGrants extends OauthGrantModel
  @relations: {
    {"user", belongs_to: "Users"}
  }

  @owner_values: (user) => { user_id: user.id }

  -- a grant is pending until the client exchanges its code for an access
  -- token
  @status_clauses: {
    active: "access_hash IS NOT NULL AND access_expires_at > #{NOW}"
    pending: "access_hash IS NULL AND code_expires_at > #{NOW}"
    expired: "(access_hash IS NULL AND code_expires_at <= #{NOW}) OR access_expires_at <= #{NOW}"
  }

  get_status: =>
    now = db.format_date!
    if @access_hash
      @access_expires_at > now and "active" or "expired"
    elseif @code_expires_at and @code_expires_at > now
      "pending"
    else
      "expired"
