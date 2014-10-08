## Get Started

Modern version of [LuaRocks](http://luarocks.org) install from the MoonRocks repository by default.
The most recent version of LuaRocks also supports uploading modules with the
`upload` command:

    $ luarocks upload my_thing-1.0-1.rockspec

For older LuaRocks installations, use [`moonrocks`](https://github.com/leafo/moonrocks):

    $ luarocks install moonrocks
    $ moonrocks upload my_thing-1.0-1.rockspec

Read more on the [About Page][1].

## What Is This Site?

**MoonRocks** is place where anyone can upload and host Lua modules.

Register an account and upload a `.rockspec` to create a new module. If your
module name is not taken it will be added to the *root manifest*.

After you have uploaded a `.rockspec`, you can upload `.rock` files for a
specific version by going to the version's page. Rock files ensure that your
module will be installable as long as this site is up.

  [1]: /about
