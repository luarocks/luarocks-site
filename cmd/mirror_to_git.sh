#!/bin/bash

repo=git@github.com:rocks-moonscript-org/moonrocks-mirror.git
path=/tmp/moonrocks_mirror

server=http://rocks.moonscript.org

abs_path=$(cd "$path" && pwd)
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

function _annotate() {
  echo "$(tput setaf 4)>>$(tput sgr0) $@"
  eval $@
}

mkdir -p "$path"

(
  cd "$path"
  git status &> /dev/null
  if [ $? -ne 0 ]; then
    _annotate git init
    _annotate git remote add origin "$repo"
    _annotate git fetch
    _annotate git checkout master
  fi
)

(
  cd "$root"
  _annotate moon "cmd/mirror_server_to_disk.moon" "$abs_path" "$server"
)

(
  cd "$path"
  git diff-index --quiet HEAD
  _annotate git add -A .
  _annotate "git commit -m 'updated backup'"
  _annotate git push origin master
)
