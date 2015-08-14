
## Changes

**2015/8/14**

* Add module follow buttons
* Add notifications for follows
* Add ability to delete individual rocks
* Split settings page apart into tabs
* Add twitter, website, and profile accounts settings fields

**2015/7/31**

* Add new header to module version page
* Add warning about uploading rock on dev version
* Add rockspec url proxying for dev versions

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
 * Fixed a a bug where API would report error when overriding a rock version even though it succeeded

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
 * Added csrf protection everywhere, updated session secret (you have to log in again sorry!)

**2012/12/5**

 * Initial release
