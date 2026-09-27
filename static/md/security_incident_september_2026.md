# LuaRocks.org Security Incident, September 2026

On September 25th, 2026 we received a report of a remote code execution
vulnerability in LuaRocks.org, coordinated through CISA. The vulnerability was
fixed on September 26th. While investigating, we found that it had been
exploited on the LuaRocks.org server several times between July 9th and August
20th, 2026.

Because an attacker was able to run code on the server, **we are treating
everything that server had access to as exposed**. The site has been moved to a
newly built server, and every credential the old server held has been revoked
and replaced.

**We have not found any evidence that existing packages were modified.**
Details on what we checked are below.

## What you should do

* **Create a new API key.** All API keys have been revoked. If you use
  `luarocks upload`, create a new key from your
  [API keys page](/settings/api-keys).
* **Log in again.** All sessions have been ended.
* **Change your password**, and change it anywhere else you've used the same
  password. Passwords are stored as bcrypt hashes, which are slow to crack, but
  the hashes should be considered exposed.
* **If you had two-factor authentication enabled, set it up again.** The
  stored 2FA secrets were exposed, so they have been removed.
* **Upgrade LuaRocks to 3.12 or newer**, especially if you use LuaJIT or Lua
  5.1. LuaRocks 3.11.1 and older on LuaJIT or Lua 5.1 will run precompiled
  bytecode if a server sends it in place of a rockspec or manifest.
* **If you installed any of the packages `bcrcewon`, `7e0b94029db0` or
  `7e0b9402f9c8`**, treat that machine as compromised. These were uploaded
  by the attacker on August 7th and have been removed.
* **Package maintainers:** we recommend reviewing the recent versions of your
  packages from the [Security Audit](/settings/security-audit) page.

## Description of the issue

Rockspecs are Lua files. When a rockspec is uploaded, LuaRocks.org runs it in a
restricted environment to read the package's name and version. The function
used to load it accepted precompiled LuaJIT bytecode as well as Lua source.
LuaJIT does not verify bytecode, so a crafted bytecode file can read and write
memory outside of the restricted environment and run arbitrary code inside the
web server.

Any registered user could trigger this by uploading a rockspec, either through
the website or the API. The code responsible had been part of LuaRocks.org for
a long time.

The fix loads rockspecs as text only and rejects bytecode.

## What happened

We found three accounts, created for this purpose, that exploited the issue:

| Date | Activity |
|---|---|
| July 9 | Shell commands were run on the server through malicious uploads |
| August 7 | Shell commands were run again, including an apparent attempt to open a remote shell. Three malicious packages were published |
| August 16, August 20 | Several hundred automated exploit attempts through the upload API, reusing the published payloads |
| September 25 | Vulnerability report received |
| September 26 | Issue fixed, site placed in read-only mode, attacker accounts suspended, malicious packages removed, all credentials revoked |

The account the web server ran as could gain full administrative access to the
server, so we assume the attacker could read anything on it, including the
entire database.

## What was exposed

Because a remote code execution took place, we assume anything on the machine
was read by the attacker:

* Account information: usernames, email addresses and bcrypt password hashes
* API keys (all revoked)
* Two-factor authentication secrets (all removed)
* Tokens from linking GitHub accounts. These only granted access to your GitHub
  profile and email address, and have all been revoked through GitHub
* Session records, account activity logs, and the IP addresses and browser
  details stored in them
* Server credentials for third-party services, which have all been revoked

## What we checked

LuaRocks.org keeps a daily mirror of all packages in git, which gave us a copy
from before the first attack to compare against.

* Every package file in storage was compared against the mirror from July 8th
  and against our database. Every difference was explained by a normal upload,
  copy or deletion made through the site
* Every upload between July 9th and September 26th was compared against the
  uploading account's usual activity, and where possible against the package's
  published source. We found no uploads made by anyone other than the account
  owner, apart from the three attacker accounts
* Every rockspec uploaded in that period was checked for bytecode. Only the
  attacker's packages contained any
* We found no changes to the site's code, no added database functions or
  roles, and no persistence mechanisms on the server

There are limits to what we could verify. A package deleted by an attacker
would look the same as one deleted by its owner, and we can't check the exact
content the compromised server sent to clients. The malicious rockspecs were
also copied to `mirror.luarocks.org` and to the public mirror repository on
GitHub, and have been removed from both.

## What we've done

* Fixed the vulnerability and added tests for it
* Put the site in read-only mode during the response
* Suspended the attacker accounts and removed their packages from the site and
  all mirrors
* Revoked all API keys and sessions, cleared password reset tokens, and removed
  two-factor authentication secrets
* Revoked all GitHub access tokens issued to LuaRocks.org
* Provisioned an entirely new server to host LuaRocks.org
* Revoked and replaced every credential the old server held

## Questions and feedback

If you have questions, open a discussion on the
[LuaRocks.org issue tracker](https://github.com/luarocks/luarocks-site/issues)
or email me directly at <leafot@gmail.com>.

Thank you to the researcher who reported this issue. We're sorry this made it
into the codebase and wasn't caught sooner.
