#!/bin/bash

BUILD_DIR="build"

[ -d "$BUILD_DIR/.git" ] && mv "$BUILD_DIR/.git" tmp_git
[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"

files=$(git ls-files | grep -v "sh$\|Tup\|gitignore\|coffee$\|scss$\|\/site.moon$" | sed -e 's/\.moon$/.lua/')
static_files=$(find static/* -type f | grep -v "Tup\|gitignore\|storage\|coffee$\|scss$")

tar -c $files | tar -C "$BUILD_DIR" -x
tar -c $static_files | tar -C "$BUILD_DIR" -x

# # copy secret
# tar -c $(find secret/* | grep -v "Tup\|moon$") | tar -C "$BUILD_DIR" -x

# # strip lua_code_cache
# cat nginx.conf | grep -v "lua_code_cache" > "$BUILD_DIR/nginx.conf"

if [ -d tmp_git ]; then
	mv tmp_git "$BUILD_DIR/.git"
	(
		cd "$BUILD_DIR"
		git checkout secret
	)
fi

