
## Changes

For a more detailed list of changes see: <https://github.com/luarocks/luarocks-site/commits/master>

**2019/3/8**

* Added [Account Activity](/settings/activity) page and started tracking various account related events (new module, profile updates, etc.)
* Revoked all API keys for [security updates](https://luarocks.org/security-incident-march-2019)
* Added ability to view revoked API keys from API keys page

**2019/3/6**

* Added Security Audit page with account server logs and summary of modules
  * Logs can be downloaded as plaintext
* Add module audit page that shows diffs to rockspecs along with dates of rocks
* Add user sessions model, logging in now requires active session.  **Every existing session has been reset, all accounts must log in again**
* Add Sessions page for managing existing sessions, and viewing IP, User Agent, Accept Lang, and last used date
  * sessions can now be disabled from web interface
* Update API to return non-200 code when handling an error
* Update design of API key page to not show the full API key by default

**2019/3/4**

* Fixed security vulnerability regarding API keys and password reset tokens
* Cleared all password reset tokens

**2018/8/31**

* Restyle headers on all pages, make site a little wider

**2017/8/18**

* Contributions from [Jeferson Siqueira](https://github.com/aajjbb) for Google Summer of Code 2017
  * Add support for staring modules
  * Add ability to follow users
  * Add ability to log in with GitHub

**2016/10/28**

* API keys can have comment added to them
* New admin panel for managing approved labels

**2016/9/30**

* You can now browse and classify modules with labels
* All labels are listed on the homepage, a module's labels are listed on its page
* Module editors can provide labels on the edit page
* Labels have been automatically imported from Lua Toolbox
* Add a method to convert Lua Toolbox endorsements to follows

Thanks to Etiene Dalcol for the work on merging Lua Toolbox into LuaRocks.org:
<https://github.com/leafo/luarocks-site/pull/86>

**2016/1/23**

* All manifests now support `.json` to render in json
* User manifests now support `.zip` zipped manifests, along with version suffix, eg. `-5.2`
* Module versions can now be archived to unlist them from the manifest

**2015/8/19**

* Add new header to all user pages
* Add GitHub account to profile settings page

**2015/8/14**

* Add module follow buttons
* Add notifications for follows
* Add ability to delete individual rocks
* Split settings page apart into tabs
* Add twitter, website, and profile accounts settings fields

**2015/7/31**

* Add new header to module version page
* Add warning about uploading rock on dev version
* Add rockspec URL proxying for dev versions (admin only)

**2015/7/27**

 * Add [top this week stats page](/stats/this-week)
 * Add [dependency stats page](/stats/dependencies)

**2015/7/26**

 * New design for module pages
 * Add [global stats page](/stats)
 * Show download counts of versions on module page
 * Show which modules depend on current module on module page
 * Modules on dependency list link to their respective module on luarocks.org
 * Add manifest recently added tab
 * Refactor CSS, refactor specs

**2015/3/27**

 * Improve searching by module name and user name
 * Re-uploading rockspec/rock now purges the files instantly

**2015/3/26**

 * Restore caching to manifests
 * Add new intro banner on homepage

**2015/2/7**

 * Added *development only* versions of manifest

**2014/7/19**

 * Added ability to search by username
 * Fixed a bug where API would report error when overriding a rock version even though it succeeded

**2014/6/4**

 * Add https
 * Add support for zipped manifests
 * Add support for HEAD request to manifest to get last modified time
 * Support for URL patterns and organizations for GitHub module claiming

**2014/6/2**

 * Users can create manifests now

**2014/6/1**

 * Added GitHub account linking and the ability to claim modules from luarocks with verified GitHub username

**2014/5/29**

 * Added `development` flag for versions, added separate `/dev/` manifest for getting only development rockspecs
 * All uploaded module versions will automatically have development flag set if the version name looks like development
 * Added module version edit page for overriding development flag

**2014/5/28**

 * Add [search page](/search)
 * Sorted modules by name on listing pages
 * Only root modules show up in recently added
 * Sort by version name on module page

**2014/3/3**

 * Add pagination to module pages
 * Rewrite queries for fetching module pages
 * Cache root manifest

**2014/3/1**

 * Add support for filtered manifests: `manifest-5.1`, `manifest-5.2`
 * Import luarocks modules
 * Add specs

**2013/6/16**

 * New modules will go into root manifest by default (unless name is taken)
 * Added API
 * Create `moonrocks` tool: <https://github.com/leafo/moonrocks>

**2013/6/9**

 * Added ability to edit modules
 * Updated module page, now shows license and homepage

**2013/6/3**

 * Added the ability to delete versions and modules
 * Fixed issues with modules that have uppercase letters in their names

**2013/3/9**

 * Added password reset to login page
 * Added user settings page with ability to update password
 * Added CSRF protection everywhere, updated session secret (you have to log in again sorry!)

**2012/12/5**

 * Initial release
