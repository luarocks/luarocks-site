#!/bin/bash

BUILD_DIR="build"

[ -d "$BUILD_DIR" ] && rm -r "$BUILD_DIR"
mkdir "$BUILD_DIR"

files=$(for file in $(git ls-files); do
	file=$(echo $file | sed -e 's/\.moon$/.lua/')
	if [ -z $(echo "$file" | grep "sh$") ]; then
		echo $file
	fi
done)

tar -c $files | tar -C "$BUILD_DIR" -x

