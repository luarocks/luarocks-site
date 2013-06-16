<div>$index</div>

## About

MoonRocks aims to be a community rock hosting service for Lua by providing an
easy way to upload rocks and rockspecs compatible with [LuaRocks][1].

Anyone can join and upload a Lua module, which gets placed in their own
Manifest. A manifest is a list of packages that LuaRocks can install from.

In addition to a user's manifest, there is also the *root manifest*: a global
manifest located at the URL of this site. Users can elect their modules into
the root manifest so others can install their module when using the root
manifest URL.

This website is supplemented by a command line tool called `moonrocks` which
lets you upload modules quickly and easily. Read more:
<http://github.com/leafo/moonrocks>

### More About Rockspecs & Rocks

Throughout the lifetime of a module, there will probably be multiple versions
created. Each version gets its own `.rockspec` file. A file containing the
version number, metadata and build instructions.

Optionally, many `.rock` files may be built for a single rockspec. A rock is a
zip file containing the rockspec and all files needed to install the module.
Some rocks may be built for a specific platform (Linux, OSX, Windows, etc). The
platform of a rock is identified by its filename.

For example, the following rockspec may result in the following rocks:

  * enet-1.0-0.rockspec
    * enet-1.0-0.src.rock
    * enet-1.0-0.win32-x86.rock


MoonRocks is a website for hosting all of these kinds of files.

### How LuaRocks Works

When you tell LuaRocks to install a package you typically do something like
this:

    ```bash
    $ luarocks install enet
    ```

LuaRocks will download a manifest from each of the manifest servers it has been
configured to look at. A manifest is a list of modules that a server has
availabe. You can see the MoonRocks root manifest by going to:
<http://rocks.moonscript.org/manifest>. It will then try to find the module
your searched for that best matches your platform and the version you want (the
most recent by default).

After finding the right match, it will ask the server with that module for
either a `.rock` or `.rockspec` which is needed to install locally. For
example, if our search was using MoonRocks, it might find this `.rockspec` if
no rocks were available: <http://rocks.moonscript.org/enet-1.0-0.rockspec>

After downloading the right file, LuaRocks will then perform the installation
and the module is ready for use.


### Using MoonRocks Manifest Without `moonrocks` Tool

If you want to always install from MoonRocks you can add the manifest url to
your LuaRocks `config.lua`:

```lua
rocks_servers = {
  "http://rocks.moonscript.org/"
}
```

And install like so:

```bash
$ luarocks install some_package
```

Alternatively you can specify the MoonRocks server as a command line flag:


```bash
$ luarocks install some_package --server=http://rocks.moonscript.org
```

### How This Site Is Built

This site is written in [MoonScript][3] using the [Lapis framework][4]. You can find the source on [GitHub][2].

  [1]: http://luarocks.org/
  [2]: http://github.com/leafo/moonrocks-site
  [3]: http://moonscript.org
  [4]: http://leafo.net/lapis/

