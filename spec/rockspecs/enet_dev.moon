[==[
package = "enet"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lua-enet.git"
}

description = {
  summary = "A library for doing network communication in Lua",
  detailed = [[
    Binding to ENet, network communication layer on top of UDP.
  ]],
  homepage = "http://leafo.net/lua-enet",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1"
}

external_dependencies = {
  ENET = {
    header = "enet/enet.h"
  }
}

build = {
  type = "builtin",
  modules = {
    enet = {
      sources = {"enet.c"},
      libraries = {"enet"},
      incdirs = {"$(ENET_INCDIR)"},
      libdirs = {"$(ENET_LIBDIR)"}
    }
  }
}
]==]
