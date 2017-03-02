<div id="gsoc-2017"></div>
## Google Summer of Code 2017

LuaRocks is part of [Google Summer of Code 2017](https://summerofcode.withgoogle.com/)!

If you are an eligible student and wish to apply, you should join the
[luarocks-developers mailing
list](https://lists.sourceforge.net/lists/listinfo/luarocks-developers) and
say hi at our [Gitter group](http://gitter.im/luarocks/luarocks). Check out
our [ideas list](http://luarocks.github.io/luarocks/gsoc/ideas2017.html) (or
share your own ideas!). Once you find a project you are interested in, you
should contact the mentor for that project by email, and this
[questionnaire](http://luarocks.github.io/luarocks/gsoc/apply2017.html). If
your application looks appropriate, the mentor may ask you to perform some
small task related to the project to assess your abilities, and discuss with
you how to best present your proposal. [Proposals accepted from March 20 to
April 3, 2017](https://summerofcode.withgoogle.com/organizations/5122941307060224/)!

<div id="quick-start"></div>
## Quick Start

Installing LuaRocks in a Unix system:

    $ wget https://luarocks.org/releases/luarocks-2.4.1.tar.gz
    $ tar zxpf luarocks-2.4.1.tar.gz
    $ cd luarocks-2.4.1
    $ ./configure; sudo make bootstrap
    $ sudo luarocks install luasocket
    $ lua
    Lua 5.3.3 Copyright (C) 1994-2016 Lua.org, PUC-Rio
    > require "socket"


On Windows? [Installation instructions for Windows](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Windows).

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
