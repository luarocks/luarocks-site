## Welcome!

**LuaRocks** is the package manager for Lua modules. 

LuaRocks allows you to install Lua modules as self-contained packages called _rocks_, which also contain version dependency information. It supports both local and remote repositories, and multiple local rocks trees. You can download and install LuaRocks on Unix and Windows.

LuaRocks is free software and uses the same license as Lua.

## Quick start

Installing LuaRocks in a Unix system:

    $ wget http://luarocks.org/releases/luarocks-2.2.1.tar.gz
    $ tar zxpf luarocks-2.2.1.tar.gz
    $ cd luarocks-2.2.1
    $ ./configure; sudo make bootstrap
    $ sudo luarocks install luasocket
    $ lua
    Lua 5.3.0 Copyright (C) 1994-2015 Lua.org, PUC-Rio
    > require "socket"

## Contributing modules

This is a place where anyone can upload and host Lua modules.

Register an account and upload a `.rockspec` to create a new module. If your
module name is not taken it will be added to the *root manifest*.

After you have uploaded a `.rockspec`, you can upload `.rock` files for a
specific version by going to the version's page. Rock files ensure that your
module will be installable as long as this site is up.

The most recent version of LuaRocks supports uploading modules with the
`upload` command:

    $ luarocks upload my_thing-1.0-1.rockspec

For older LuaRocks installations, you can use [`moonrocks`](https://github.com/leafo/moonrocks):

    $ luarocks install moonrocks
    $ moonrocks upload my_thing-1.0-1.rockspec

Read more on the [About Page][1].

  [1]: /about
