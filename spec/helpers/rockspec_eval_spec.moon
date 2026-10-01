config = require("lapis.config").get!

import eval_rockspec, run_sandboxed, get_sandbox_source, decode_result from require "helpers.rockspec_eval"

-- busted may run on PUC Lua, but the sandbox always runs on LuaJIT
bytecode = string.dump -> 1

can_bwrap = ->
  return false unless io.open "/usr/bin/bwrap"
  status = os.execute "unshare -Ur true > /dev/null 2>&1"
  status == 0 or status == true

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

  describe "in process", ->
    before_each ->
      config.rockspec_sandbox = nil

    data_tests!

  describe "child process", ->
    before_each ->
      config.rockspec_sandbox = {}

    data_tests!

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

    it "evaluates a rockspec", ->
      unless can_bwrap!
        pending "bubblewrap is unavailable"
        return

      spec = assert eval_rockspec [[package = "my-module"]]
      assert.same { package: "my-module" }, spec

    it "hides the site's files", ->
      unless can_bwrap!
        pending "bubblewrap is unavailable"
        return

      site_config = "#{io.popen("pwd")\read "*l"}/config.moon"
      assert io.open site_config

      out = run_sandboxed string.format([[
        io.write(tostring(io.open(%q) ~= nil), " ", tostring(io.open("/etc/passwd") ~= nil))
      ]], site_config), ""
      assert.same "false false", out
