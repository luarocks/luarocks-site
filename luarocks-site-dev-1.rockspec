package = "luarocks-site"
version = "dev-1"
source = {
  url = "git@github.com:luarocks/luarocks-site.git"
}
description = {
  summary = "<https://luarocks.org>",
  detailed = "<https://luarocks.org>",
  homepage = "http://luarocks.org",
  license = "MIT"
}
dependencies = {
  "lua ~> 5.1",
  "moonscript",
  "bcrypt == 2.1-6", -- Note: future versions of bcrypt will fail to verify due to prefix change 2y vs 2b
  "luabitop",
  "pgmoon ~> 1.15",
  "lapis ~> 1.10",
  "lapis-exceptions ~> 2",
  "lapis-console ~> 1.2",
  "lapis-systemd ~> 1.0",
  "tableshape ~> 2.4",
  "mailgun ~> 1.2",
  "cloud_storage ~> 1.3",
  "lzlib", -- zipwriter dependency
  "struct >= 1.2", -- zipwriter dependency
  "zipwriter ~> 0.1.5",
  "moonrocks ~> 1.1",
}
build = {
   type = "none",
}
