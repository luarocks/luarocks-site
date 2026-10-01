config = require("lapis.config").get!

import eval_rockspec, run_sandboxed, get_sandbox_source, decode_result from require "helpers.rockspec_eval"
import shell_escape from require "lapis.cmd.path"

RESTY = "/usr/local/openresty/bin/resty"

-- busted may run on PUC Lua, but the sandbox always runs on LuaJIT
bytecode = string.dump -> 1

local bwrap_available
can_bwrap = ->
  if bwrap_available == nil
    status = io.open("/usr/bin/bwrap") and os.execute "unshare -Ur true > /dev/null 2>&1"
    bwrap_available = status == 0 or status == true
  bwrap_available

-- CI sets REQUIRE_SANDBOX so a missing dependency fails the build instead of
-- quietly skipping the specs that cover production's configuration
skip = (reason) ->
  assert not os.getenv("REQUIRE_SANDBOX"), reason
  pending reason

bwrap_it = (name, fn) ->
  it name, ->
    return skip "bubblewrap is unavailable" unless can_bwrap!
    fn!

-- Runs lua with resty, where the child is run with ngx.pipe like it is in
-- the web server. Returns everything it printed
run_resty = (lua) ->
  f = assert io.popen "LAPIS_ENVIRONMENT=test #{RESTY} -I . -e '#{shell_escape lua}' 2>&1"
  with f\read "*a"
    f\close!

resty_eval = (rockspec) ->
  run_resty string.format [[
    local config = require("lapis.config").get()
    config.rockspec_sandbox = { bwrap = true }
    local spec, err = require("helpers.rockspec_eval").eval_rockspec(%q)
    io.write("result: ", tostring(spec and spec.package), " ", tostring(err))
  ]], rockspec

describe "helpers.rockspec_eval", ->
  local original

  before_each ->
    original = config.rockspec_sandbox

  after_each ->
    config.rockspec_sandbox = original

  data_tests = ->
    it "evaluates a rockspec into plain data", ->
      spec = assert eval_rockspec [[
        package = "my-module"
        version = "1.0-1"
        local base = "https://example.com/"
        source = { url = base .. ("my-module"):gsub("-", "_") .. ".tar.gz" }
        dependencies = { "lua >= 5.1", "lpeg" }
        build = { type = "builtin", copy_directories = {}, modules = { ["a.b"] = "a/b.lua" } }
        flag = true
        count = 2.5
      ]]

      assert.same {
        package: "my-module"
        version: "1.0-1"
        source: { url: "https://example.com/my_module.tar.gz" }
        dependencies: { "lua >= 5.1", "lpeg" }
        build: { type: "builtin", copy_directories: {}, modules: { "a.b": "a/b.lua" } }
        flag: true
        count: 2.5
      }, spec

    it "keeps bytes exactly", ->
      spec = assert eval_rockspec 'package = "a\\255\\0b\\"\\n"'
      assert.same "a\255\0b\"\n", spec.package

    it "drops values that aren't data", ->
      spec = assert eval_rockspec [[
        package = "my-module"
        helper = function() end
        nan = 0/0
        inf = { 1/0, [true] = "x", [{}] = "y", ok = 1 }
      ]]
      assert.same { package: "my-module", inf: { ok: 1 } }, spec

    it "rejects cycles", ->
      spec, err = eval_rockspec "a = {} a.self = a"
      assert.falsy spec
      assert.same "Invalid rockspec (too complex)", err

    it "rejects oversized strings", ->
      spec, err = eval_rockspec [[x = ("x"):rep(2 * 1024 * 1024)]]
      assert.falsy spec
      assert.same "Invalid rockspec (too complex)", err

    it "rejects precompiled bytecode", ->
      spec, err = eval_rockspec bytecode
      assert.falsy spec
      assert.same "Failed to parse rockspec", err

    it "rejects syntax errors", ->
      spec, err = eval_rockspec "package = "
      assert.falsy spec
      assert.same "Failed to parse rockspec", err

    it "rejects runtime errors", ->
      spec, err = eval_rockspec "package = nothing.here"
      assert.falsy spec
      assert.same "Failed to eval rockspec", err

  limit_tests = (it) ->
    it "kills a backtracking pattern", ->
      spec, err = eval_rockspec [[x = ("a"):rep(30000):find(".-.-.-.-b")]]
      assert.falsy spec
      assert.same "Failed to eval rockspec", err

    it "limits memory", ->
      spec, err = eval_rockspec [[x = ("x"):rep(2^30)]]
      assert.falsy spec
      assert.same "Failed to eval rockspec", err

    it "stops an infinite loop", ->
      spec, err = eval_rockspec [[while true do end]]
      assert.falsy spec
      assert.same "Failed to eval rockspec", err

  describe "in process", ->
    before_each ->
      config.rockspec_sandbox = nil

    data_tests!

  describe "child process", ->
    before_each ->
      config.rockspec_sandbox = {}

    data_tests!
    limit_tests it

    it "reports a sandbox that can't start", ->
      config.rockspec_sandbox = { luajit: "/nonexistent" }
      spec, err = eval_rockspec [[package = "my-module"]]
      assert.falsy spec
      assert.same "Failed to run rockspec sandbox", err

    it "rejects non-finite numbers from the child", ->
      assert.same {nil, "Failed to eval rockspec"}, {decode_result '{"ok":[[NaN,1]]}'}
      assert.same {nil, "Failed to eval rockspec"}, {decode_result '{"ok":[["x",Infinity]]}'}

    it "runs with an empty environment", ->
      out = run_sandboxed [[io.write(tostring(os.getenv("HOME")))]], ""
      assert.same "nil", out

    it "closes inherited file descriptors", ->
      -- runs the sandbox as a module, then counts open descriptors above
      -- stderr before and after closing them
      source = table.concat {
        "local sandbox = (function(...) "
        get_sandbox_source!
        "\nend)('rockspec_sandbox')\n"
        [[
          local ffi = require("ffi")
          ffi.cdef("int fcntl(int fd, int cmd, ...);")
          local function count()
            local n = 0
            for fd = 3, 255 do
              if ffi.C.fcntl(fd, 1) ~= -1 then n = n + 1 end
            end
            return n
          end
          local before = count()
          sandbox.close_inherited_fds()
          io.write(before, " ", count())
        ]]
      }

      held = assert io.open "config.moon"
      out = run_sandboxed source, ""
      held\close!

      before, after = out\match "^(%d+) (%d+)$"
      assert.truthy tonumber(before) > 0, "expected an inherited descriptor, got: #{out}"
      assert.same "0", after

  describe "bubblewrap", ->
    before_each ->
      config.rockspec_sandbox = { bwrap: true }

    bwrap_it "evaluates a rockspec", ->
      spec = assert eval_rockspec [[package = "my-module"]]
      assert.same { package: "my-module" }, spec

    limit_tests bwrap_it

    bwrap_it "hides the site's files", ->
      site_config = "#{io.popen("pwd")\read "*l"}/config.moon"
      assert io.open site_config

      out = run_sandboxed string.format([[
        io.write(tostring(io.open(%q) ~= nil), " ", tostring(io.open("/etc/passwd") ~= nil))
      ]], site_config), ""
      assert.same "false false", out

    bwrap_it "has no network", ->
      -- a udp connect to 1.1.1.1:53 sends nothing, it only needs a route
      out = run_sandboxed [[
        local ffi = require("ffi")
        ffi.cdef("int socket(int domain, int type, int protocol); int connect(int fd, const void *addr, unsigned int len);")
        local addr = ffi.new("uint8_t[16]", {2, 0, 0, 53, 1, 1, 1, 1})
        io.write(tostring(ffi.C.connect(ffi.C.socket(2, 2, 0), addr, 16)))
      ]], ""
      assert.same "-1", out

  describe "inside nginx", ->
    resty_it = (name, fn) ->
      it name, ->
        return skip "resty is unavailable" unless io.open RESTY
        fn!

    resty_it "evaluates a rockspec under bubblewrap", ->
      return skip "bubblewrap is unavailable" unless can_bwrap!
      out = resty_eval [[package = "my-module"]]
      assert.truthy out\find("result: my-module nil", 1, true), out

    resty_it "kills a backtracking pattern under bubblewrap", ->
      return skip "bubblewrap is unavailable" unless can_bwrap!
      out = resty_eval [[x = ("a"):rep(30000):find(".-.-.-.-b")]]
      assert.truthy out\find("result: nil Failed to eval rockspec", 1, true), out

    resty_it "applies the timeout to the whole run", ->
      -- each write restarts a per operation timeout, but not the deadline
      out = run_resty [[
        local config = require("lapis.config").get()
        local out, err = require("helpers.rockspec_eval").run_sandboxed([=[
          for i = 1, 20 do
            os.execute("/usr/bin/sleep 0.3")
            io.write("a")
            io.stdout:flush()
          end
        ]=], "", { timeout = 1 })
        io.write("result: ", tostring(err))
      ]]
      assert.truthy out\find("result: timeout", 1, true), out
