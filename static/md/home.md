<div id="quick-start"></div>
## Quick Start

Installing LuaRocks in a Unix system:

    $ wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz
    $ tar zxpf luarocks-3.11.1.tar.gz
    $ cd luarocks-3.11.1
    $ ./configure && make && sudo make install
    $ sudo luarocks install luasocket
    $ lua
    Lua 5.3.5 Copyright (C) 1994-2018 Lua.org, PUC-Rio
    > require "socket"

On Windows? [Installation instructions for Windows](https://github.com/luarocks/luarocks/blob/main/docs/installation_instructions_for_windows.md).

## Contributing Modules

Anyone can upload and host Lua modules.

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
