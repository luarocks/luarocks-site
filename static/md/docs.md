## LuaRocks Documentation

### LuaRocks.org API

Documentation for the LuaRocks.org upload API, used by the `luarocks upload`
command.

[View API Documentation](/docs/api)

### LuaRocks CLI Documentation

Complete documentation for the LuaRocks command-line package manager, including
installation, configuration, and usage guides.

[View LuaRocks Documentation](https://github.com/luarocks/luarocks/blob/main/docs/index.md)

### Manifests

Manifests are index files that list all available modules, their versions, and download locations. The LuaRocks CLI uses manifests to discover and install packages.

#### Using Manifests with LuaRocks

Use the `--server` option to specify which manifest root path to install from:

```bash
luarocks install --server=<root-path> <module-name>
```

#### Manifest Root Paths

LuaRocks.org provides several manifest root paths, each serving a different subset of modules:

| Root Path | Description |
|-----------|-------------|
| `https://luarocks.org` | All stable modules (default) |
| `https://luarocks.org/dev` | Development versions only |
| `https://luarocks.org/manifests/:username` | All modules by a specific user |
| `https://luarocks.org/m/:name` | Custom manifest (stable versions) |
| `https://luarocks.org/m/:name/dev` | Custom manifest (dev versions) |

#### Available Paths Under Each Root

Each manifest root path serves the following manifest files:

| Path | Description |
|------|-------------|
| `/manifest` | All modules (all Lua versions) |
| `/manifest-5.1` | Modules compatible with Lua 5.1 |
| `/manifest-5.2` | Modules compatible with Lua 5.2 |
| `/manifest-5.3` | Modules compatible with Lua 5.3 |
| `/manifest-5.4` | Modules compatible with Lua 5.4 |

For example, `https://luarocks.org/dev/manifest-5.4` returns development versions compatible with Lua 5.4.

#### Manifest File Structure

Manifest files are Lua tables with the following structure:

```lua
{
  repository = {
    ["module_name"] = {
      ["version"] = {
        { arch = "rockspec" },
        { arch = "linux-x86_64" },
        -- additional architectures...
      }
    }
  },
  commands = {},
  modules = {}
}
```

The `repository` table maps module names to versions to available architectures. Each version entry lists the available architectures, which always includes `"rockspec"` for the source specification. Binary rocks are listed with their platform architecture (e.g., `"linux-x86_64"`, `"macosx-arm64"`).

The `commands` and `modules` tables provide reverse mappings from executable names and Lua module names back to their packages. These are used internally by LuaRocks for dependency resolution.

#### Accessing Module Files

The manifest root path also serves the actual module files (rockspecs and rocks). Files are accessed relative to the manifest root using these patterns:

| File Type | Path Pattern | Example |
|-----------|--------------|---------|
| Rockspec | `/{module}-{version}.rockspec` | `/lpeg-1.0.2-1.rockspec` |
| Rock (source) | `/{module}-{version}.src.rock` | `/lpeg-1.0.2-1.src.rock` |
| Rock (binary) | `/{module}-{version}.{arch}.rock` | `/lpeg-1.0.2-1.linux-x86_64.rock` |

For example, using `--server=https://luarocks.org/manifests/luarocks`, the rockspec for lpeg would be available at `https://luarocks.org/manifests/luarocks/lpeg-1.0.2-1.rockspec`.

#### Output Formats

All manifest URLs return a Lua table by default. Append `.json` for JSON format or `.zip` for compressed format. For example: `/manifest.json` or `/manifest-5.4.zip`.

#### Custom Manifests

Users can create curated manifests at `/m/:name`. Custom manifests can be:

* **Open**: Anyone can add their modules
* **Closed**: Only manifest admins can add modules

#### Usage Examples

Install from the root manifest (default):

```bash
luarocks install lpeg
```

Install a development version:

```bash
luarocks install --server=https://luarocks.org/dev lpeg
```

Install from a user manifest:

```bash
luarocks install --server=https://luarocks.org/manifests/luarocks lpeg
```

Install from a custom manifest:

```bash
luarocks install --server=https://luarocks.org/m/mymanifest mymodule
```

#### Mirrors

Alternative servers are available for accessing LuaRocks packages:

**HTTP Mirror**

* `https://mirror.luarocks.org/` - An alternative server for accessing LuaRocks packages

**GitHub Repository Mirrors**

Daily git backups of the manifest data:

* [moonrocks-mirror](https://github.com/rocks-moonscript-org/moonrocks-mirror) - Root manifest backup
* [moonrocks-dev-mirror](https://github.com/rocks-moonscript-org/moonrocks-dev-mirror) - Dev manifest backup

These GitHub mirrors can be used directly as a LuaRocks server via raw.githubusercontent.com:

```bash
luarocks install --server=https://raw.githubusercontent.com/rocks-moonscript-org/moonrocks-mirror/master lpeg
```

For dev versions:

```bash
luarocks install --server=https://raw.githubusercontent.com/rocks-moonscript-org/moonrocks-dev-mirror/master lpeg
```

This can be useful as a fallback if the main LuaRocks.org server is unavailable.
