#!/bin/bash

BUILD_DIR="build"

[ -d "$BUILD_DIR/.git" ] && mv "$BUILD_DIR/.git" tmp_git
[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"

files=$(git ls-files | grep -v "sh$\|Tup\|gitignore\|coffee$\|scss$" | sed -e 's/\.moon$/.lua/')
tar -c $files | tar -C "$BUILD_DIR" -x

# copy secret
tar -c $(find secret/* | grep -v "Tup\|moon$") | tar -C "$BUILD_DIR" -x

# copy assets
tar -c $(find static/* | grep -v "Tup\|coffee$\|scss$") | tar -C "$BUILD_DIR" -x

# strip lua_code_cache
cat nginx.conf | grep -v "lua_code_cache" > "$BUILD_DIR/nginx.conf"

[ -d tmp_git ] && mv tmp_git "$BUILD_DIR/.git"

