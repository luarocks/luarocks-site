#!/bin/bash
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(
  cd "$root"
  moon "cmd/update_mirrors.moon"
)

