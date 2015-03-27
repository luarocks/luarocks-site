file = io.popen "git rev-parse --short HEAD"
with file\read "*a"
  file\close!
