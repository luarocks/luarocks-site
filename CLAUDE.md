# LuaRocks.org Development Guide

## Build Commands
- `tup` - Build all MoonScript and SCSS files. Not necessary to run this manually as monitor will be running during development.
- `tup monitor -a` - Watch filesystem and rebuild on changes
- `make install_deps` - Install Lua dependencies from LuaRocks
- `make lint` - Lint MoonScript files
- `make test` - Run all tests with Busted
- `busted spec/file_spec.moon` - Run single test file
- `make test_db` - Setup test database, only necessary if test database is missing
- `make migrate` - Run database migrations
- `lapis server` - Start local development server

## Code Style
- **Language**: MoonScript with Lapis framework
- **Styles**: SCSS is used for writing CSS
- **Indentation**: 2 spaces
- **Imports**: Group at top of file, ordered by dependency
- **Naming**: snake_case for variables/functions, CamelCase for classes
- **Error handling**: Return nil + error message for recoverable errors
- **Types**: Use class methods to check types where appropriate
- **Format**: No trailing whitespace, newline at end of file
- **Documentation**: Comment complex logic, document public APIs
- **Testing**: Write tests in Busted framework using spec format

Use automated tools (`make lint`, `make test`) before committing changes.


## Application controllers

In every request, the following are available by default from the before filter:

- `@current_user` -- The currently logged in user, or `nil`. Instance of models/users.moon 
- `@current_user_session` -- The session object of currently logged in user or `nil`. Instance of models/user_sessions.moon
- `@csrf_token`


