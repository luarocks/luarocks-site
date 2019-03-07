
# Luarocks.org Security Incident March 2019

On March 4th we were made aware of a security vulnerability on LuaRocks.org.
The issue was immediately patched. The vulnerability was detected by Igor
Kanygin and Maksim Duyunov, Positive Research Center (Positive Technologies
Company).

**We did an initial audit of our logs and database and have not found any
evidence of anyone attempting to exploit this issue**, but we're continuing to
do an indepth search along with providing some tools to account owners to check
their own accounts.

**If you have an account, please go to the Security Audit page from your
account settings as soon as you have time:
<https://luarocks.org/settings/security-audit>**.

In addition to the audit, we're releasing a series of security related updates
to give people better control over their account.

***Note:** If you were previously logged in, all sessions have been invalidated
to transition to a new session management system. Please log in again.*

## Description of issue

A `generate_key` function was being used to generate a random string of text
for API keys and password reset tokens. This function was using Lua's
`math.random` function instead of a cryptographically secure method.

Because LuaRocks.org is opensource, someone could gain understanding of how the
system works and guess the random number generator's seed. Using this they
could attempt to guess password reset tokens and API keys. The default random
number generator was also seeded using a plain Unix timestamp. The random
number generator was only used for API keys and password reset tokens so the
search space to guess the tokens was small, as nothing else as would have been
incrementing the seed.

The piece of code responsible for this was part of LuaRocks.org from the very
beginning, so the issue was exploitable from the beginning.

## What's at stake

LuaRocks.org is a package manager, so the security of accounts is critical.
Package owners have a one-to-many relationship with their community, meaning a
single compromised package could affect many developers, and potentially many
more consumers. Although we haven't found evidence of an exploit, we must
assume the worst when planning out response.

Here's a breakdown of how someone may have exploited the issue:

* **Guessing an API key** -- API keys give access to two methods on an account:
  * `upload`: A user can upload a brand new package or version of a package by providing a rockspec
    * It's possible to overwrite an existing version's rockspec
  * `upload-rock`: A user can upload a zip file (`rock` file), containing either binary or source for a particular package
    * It's possible to replace an existing version's `rock` files

* **Guessing a password reset token** -- A password reset token will allow someone to access your account from the web UI
  * The password would be changed, so you would know if your account has been tampered with
  * **LuaRocks.org UI lacks the ability to change email address and username on an account,** so a hijacked account could not be stolen
  * Any of the upload functions listed above can be done from the web interface
  * Minimal metadata about packages could be updated, like the homepage, description, or title

We've been using our server logs and database changes to look for signs of
tampering. Sadly, LuaRocks.org is very simple website and lacks many security
logging features. Additionally, due to how our server logs were configured, we
don't have historical IP address logs. We're addressing all of these issues to
ensure we have proper logging going forward.

If we assume the worst then we must question the integrity of all packages on
the site. We're asking all account holders to use the new [Security Audit panel](/settings/security-audit)
from their account to review their packages. Things to look for are:

* Changes to rockspecs you didn't make
* Updated rock files

It's easier for us to verify rockspec files since they are plain text. Because
`rock` files are zip files, it's harder for us to verify their integrity.

We're investigating purging all rock files and manually rebuilding them where
we can while asking developers to rebuild them as well.

## What we've done and what we will be doing

Here's what we've already done:

* Patched the issue and verified there are no related instances of it
* Cleared all password reset tokens
* Revoked all API keys
* Added Security Audit page:
  * You can view/download all server logs we have associated to your account
  * You can review diffs for all rockspecs on your account
* Added "Account sessions" panel so you can manage which browsers have active sessions to your account
  * All sessions are managed, all accounts have been logged out to support the new system.

Here's what we're working on now:

* **Implementing package singing and verifying to verify integrity of package files**
  * this will enable us to verify that files have come directly from package maintainers, prevning any future isuses concerning tampering
* Added two factor authentication to accounts on LuaRocks.org
* Adding general purpose account activity log that tracks all changes to any data associated with an account
* Investigating building rock files server-side, and rebuilding all existing rocks where we can

## Questions and feedback

If you have any feedback or requests about how we have been or should be
handling this issue please reach out. You can open a discussion on the
[LuaRocks.org issue tracker](https://github.com/luarocks/luarocks-site/issues)
or email me directly, <leafot@gmail.com>.

We're very sorry that this mistake made it into the codebase and was not
discovered earlier. LuaRocks.org is built with security in mind, but mistakes
happen. If you're a security researcher or know someone who would like to
donate their time to investigate this project further than please get in touch.


