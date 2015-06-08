## About this site

LuaRocks.org is a community run `rock` and `rockspec` hosting service for Lua
modules.  It provides an easy way to upload rocks and rockspecs compatible with
the [LuaRocks][1] package manager.

Anyone can join and upload a Lua module. Modules are places in manifests,
centralized lists of packages that LuaRocks can install from.

The *root manifest* is the global manifest on LuaRocks.org. It's a single
namespace containing all the packages that can be installed right from LuaRocks
with no additional configuration. In addition to the root manifest, all
accounts have their own manifests with modules uploaded by the account, and
anyone can [create a custom manifest](/new-manifest) for organizing collections
of modules.

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


LuaRocks.org is a website for hosting all of these kinds of files.

Some module versions may be marked as *development*. These versions are placed
in a development version of their regular manifest so they won't be installed
by default. This site will automatically identify a module version as
development by it's name. The owner of the module can override the
classification if it was miscategorized.

### How LuaRocks Works

When you tell LuaRocks to install a package you typically do something like
this:

    $ luarocks install enet

LuaRocks will download a manifest from each of the manifest servers it has been
configured to look at. A manifest is a list of modules that a server has
available. You can see the LuaRocks root manifest by going to:
<http://luarocks.org/manifest>. It will then try to find the module
you searched for that best matches your platform and the version you want (the
most recent by default).

After finding the right match, it will ask the server with that module for
either a `.rock` or `.rockspec` which is needed to install locally. For
example, if our search was using LuaRocks.org, it might find this `.rockspec` if
no rocks were available: <http://luarocks.org/enet-1.0-0.rockspec>

After downloading the right file, LuaRocks will then perform the installation
and the module is ready for use.

### How This Site Is Built

This site is written in [MoonScript][3] using the [Lapis framework][4]. You can find the source on [GitHub][2].

  [1]: http://luarocks.org/
  [2]: http://github.com/leafo/moonrocks-site
  [3]: http://moonscript.org
  [4]: http://leafo.net/lapis/

