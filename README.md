# LuaRocks.org

<http://luarocks.org>

[![Build Status](https://travis-ci.org/leafo/luarocks-site.svg?branch=master)](https://travis-ci.org/leafo/luarocks-site)

The official module repository of the [LuaRocks package manager](https://github.com/keplerproject/luarocks) for Lua.

The entire site runs on [OpenResty][1], an Nginx based platform with Lua
support. The site itself is coded in [MoonScript][2] and uses [Lapis][3] as a
web framework.

Files are stored on Google Cloud Storage. PostgreSQL is used as a database.

[Tup][4] is the build system.

## How To Run Locally

Install the following dependencies:

* [Tup][4]
* [sassc](https://github.com/sass/sassc)
* [coffeescript](http://coffeescript.org/#installation)
* [discount](http://www.pell.portland.or.us/~orc/Code/discount/) (or something that provides `markdown` executable)
* PostgreSQL
* [OpenResty][1]
* Redis

Check out this repository.

Install the dependencies listed in
<https://github.com/leafo/moonrocks-site/blob/master/BoxFile> with LuaRocks.

Run these commands to build.

```bash
tup init
tup
```

Create the schema:

```bash
make init_schema
```

Start the server:

```bash
lapis server
```

Now `http://localhost:8080` should load.

If you edit any MoonScript or SCSS files you should call `tup` to rebuild
the changes. You can run `tup monitor -a` to watch the filesystem to rebuild.

### Running tests

This site uses [Busted](http://olivinelabs.com/busted/) for its tests:

```bash
make test_db
busted
```

The `make test_db` command will copy the schema of the `moonrocks` local
database into the test database, wiping out what whatever was there. You'll
only need to run this command once and the beginning any any time the schema
has changed.

### Setting up Google Cloud Storage

In production all files are stored on Google Cloud Storage. With no
configuration (default), files are stored on the file system using the storage
bucket mock provided by the `cloud_storage` rock.

To configure `cloud_storage` to talk to a live bucket make a file
`secret/storage_bucket.moon`, it must return a bucket instance. It might look
something like:


```moonscript
-- secret/storage_bucket.moon
import OAuth from require "cloud_storage.oauth"
import CloudStorage from require "cloud_storage.google"

o = OAuth "NUMBER@developer.gserviceaccount.com", "PRIVATEKEY.pem"
CloudStorage(o, "PROJECT_ID")\bucket "BUCKET_NAME"
```

### Setting up email

If you want to test sending emails you'll have to provide [Mailgun][5]
credentials. A test account is free. Create a file `secret/email.moon` and
make it look something like this: (it must return a table of options)

```moonscript
{ -- secret/email.moon
  key: "api:key-MY_KEY"
  domain: "mydomain.mailgun.org"
  sender: "MoonRocks <postmaster@mydomain.mailgun.org>"
}
```

  [1]: http://openresty.org/
  [2]: http://moonscript.org/
  [3]: https://github.com/leafo/lapis
  [4]: http://gittup.org/tup/
  [5]: http://www.mailgun.com/


