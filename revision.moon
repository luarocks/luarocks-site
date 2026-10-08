-- production workers can't run git (different owner), so bin/deploy writes REVISION
file = io.open("REVISION") or io.popen "git rev-parse --short HEAD"
rev = file\read "*a"
file\close!
rev\gsub "%s+$", ""
