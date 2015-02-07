# LuaRocks.org

<http://luarocks.org>

A webpage for hosting and serving Lua modules.

This was formerly called [MoonRocks](http://rocks.moonscript.org), but has
since taken over as the official LuaRocks website. This naming history
is apparent in its implementation.

The entire site runs on [OpenResty][1], an Nginx based platform with Lua
support. The site itself is coded in [MoonScript][2] and uses [Lapis][3] as a
web framework.

Files are stored on Google Cloud Storage. PostgreSQL is used as a database.

[Tup][4] is the build system.

## How To Run Locally

This is a bit complicated, tell me if you are doing this and I'll assist you.

Install [sassc](https://github.com/hcatlin/sassc). (Optionally you can install
[SASS](http://sass-lang.com/) but you'll need to modify a Tupfile)

Install [coffeescript](http://coffeescript.org/#installation).

Install [discount](http://www.pell.portland.or.us/~orc/Code/discount/) (or something that provides `markdown` binary).

Install PostgreSQL. Create a database called `moonrocks`.

Install [OpenResty][1].

Check out this repository.

Install the dependencies listed in
<https://github.com/leafo/moonrocks-site/blob/master/BoxFile>.

If you use [MoonBox][6] then you can install all of the files in one go:

```bash
moonbox install
source moonbox env enter
```

Run these commands to build.

```bash
tup init
tup upd
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

### Why Tup?

Tup has a filesystem monitor, it can rebuild any assets or moon files
automatically as you change them. Better than running individual watch scripts
for each component.

To use it run:

```bash
tup monitor -a -f
```


  [1]: http://openresty.org/
  [2]: http://moonscript.org/
  [3]: https://github.com/leafo/lapis
  [4]: http://gittup.org/tup/
  [5]: http://www.mailgun.com/
  [6]: https://github.com/kernelp4nic/moonbox


