## LuaRocks.org API Documentation

The LuaRocks.org API allows you to programmatically upload rockspecs and rocks
to your account. This is the same API used by the `luarocks upload` command.

### Authentication

Most API endpoints require authentication via an API key. You can generate an
API key from your [account settings](/settings/api-keys).

API keys are passed as part of the URL path: `/api/1/:key/endpoint`

**Keep your API key secret.** Anyone with your key can upload modules to your
account. If you believe your key has been compromised, revoke it immediately
from your account settings and generate a new one.

### Error Responses

All endpoints return JSON. On error, the response will contain an `errors`
array:

```json
{
  "errors": ["Error message here"]
}
```

Common HTTP status codes:

| Status | Description |
|--------|-------------|
| 200 | Success |
| 400 | Bad request (validation error) |
| 401 | Invalid API key |
| 403 | API key revoked or account suspended |
| 404 | Resource not found |

---

## Endpoints

### Get Tool Version

Returns the current tool version configured on the server.

```
GET /api/tool_version
```

**Authentication:** None required

**Response:**

```json
{
  "version": "3.0.0"
}
```

---

### Get API Key Status

Check the status of your API key and get your user ID.

```
GET /api/1/:key/status
```

**Authentication:** Required

**Response:**

```json
{
  "user_id": 123,
  "created_at": "2024-01-15 10:30:00"
}
```

---

### Check Rockspec

Check if a specific package version already exists in your account.

```
GET /api/1/:key/check_rockspec?package=:package&version=:version
```

**Authentication:** Required

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| package | string | Yes | The package name (case-insensitive) |
| version | string | Yes | The version string (case-insensitive) |

**Response:**

```json
{
  "module": { ... },
  "version": { ... }
}
```

Both `module` and `version` will be `null` if not found. If the module exists
but not the specific version, only `version` will be `null`.

---

### Upload Rockspec

Upload a new rockspec file. This will create a new module if it doesn't exist,
or add a new version to an existing module.

```
POST /api/1/:key/upload
```

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| rockspec_file | file | Yes | The `.rockspec` file to upload |

**Response:**

```json
{
  "module": {
    "id": 123,
    "name": "mymodule",
    "current_version_id": 456
  },
  "version": {
    "id": 456,
    "version_name": "1.0-1",
    "module_id": 123
  },
  "module_url": "https://luarocks.org/modules/username/mymodule",
  "manifests": [
    {
      "id": 1,
      "name": "root"
    }
  ],
  "is_new": true
}
```

The `is_new` field indicates whether this created a new module (`true`) or
added a version to an existing module (`false`).

---

### Upload Rock

Upload a compiled rock file for an existing version.

```
POST /api/1/:key/upload_rock/:version_id
```

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| version_id | integer | Yes | The version ID (from URL path) |
| rock_file | file | Yes | The `.rock` file to upload |

**Response:**

```json
{
  "rock": {
    "id": 789,
    "arch": "linux-x86_64",
    "revision": 1
  },
  "module_url": "https://luarocks.org/modules/username/mymodule"
}
```

**Errors:**

- `404` - Invalid version ID

---

## Usage with LuaRocks CLI

The easiest way to use the API is through the LuaRocks command-line tool:

```bash
# Upload a rockspec
luarocks upload mymodule-1.0-1.rockspec --api-key=YOUR_API_KEY

# Upload a rockspec and build/upload a rock
luarocks upload mymodule-1.0-1.rockspec --api-key=YOUR_API_KEY
```

You can also store your API key in a config file to avoid passing it on each
command. See the [LuaRocks documentation][1] for more details.

  [1]: https://github.com/luarocks/luarocks/wiki/upload

