-- Evaluates a rockspec in a sandbox. Rockspecs are Lua files, hence untrusted
-- code, that we need to evaluate, so we take special precautions:
--
-- * only source text is loaded, precompiled bytecode is rejected
-- * the code runs with an empty environment, so it has no globals
-- * a line count hook stops rockspecs that loop
-- * the result is copied into plain data (strings, numbers, booleans,
--   tables), with limits on depth and size
--
-- With the rockspec_sandbox config set, evaluation also runs in a child
-- process:
--
-- * prlimit caps its cpu time and memory, and it is killed after a wall
--   clock timeout
-- * it starts with no environment variables and closes inherited file
--   descriptors
-- * the result is read back from its stdout as JSON, and anything in it
--   besides the plain data types above is rejected
-- * with the bwrap option it also has no network and sees no files besides
--   luajit and system libraries
--
--   rockspec_sandbox {
--     bwrap: true -- also run the child under bubblewrap (production)
--     luajit: "/usr/local/openresty/luajit/bin/luajit"
--     cpu_seconds: 2
--     memory_bytes: 512 * 1024 * 1024
--     timeout: 3 -- wall clock seconds before the child is killed
--   }

config = require("lapis.config").get!
cjson = require "cjson"
sandbox = require "helpers.rockspec_sandbox"

import shell_escape from require "lapis.cmd.path"
import ERRORS, is_finite from sandbox

-- more than the JSON encoding of the largest data the sandbox's to_data
-- allows, so only a misbehaving child reaches it
MAX_OUTPUT = 16 * 1024 * 1024

DEFAULT_LUAJIT = "/usr/local/openresty/luajit/bin/luajit"

local sandbox_source

-- The child runs helpers/rockspec_sandbox.lua passed with -e so the sandbox
-- doesn't need access to the site's files
get_sandbox_source = ->
  return sandbox_source if sandbox_source
  name = "helpers.rockspec_sandbox"
  path = if package.searchpath
    package.searchpath name, package.path
  else
    fname = name\gsub "%.", "/"
    local found
    for template in package.path\gmatch "[^;]+"
      candidate = template\gsub "%?", fname
      if f = io.open candidate
        f\close!
        found = candidate
        break
    found

  assert path, "failed to find #{name}"
  f = assert io.open path
  sandbox_source = f\read "*a"
  f\close!
  sandbox_source

sandbox_command = (opts, source) ->
  luajit = opts.luajit or DEFAULT_LUAJIT

  command = {
    "/usr/bin/env", "-i"
    "/usr/bin/prlimit"
    "--cpu=#{opts.cpu_seconds or 2}"
    "--as=#{opts.memory_bytes or 512 * 1024 * 1024}"
    "--core=0"
    "--"
  }

  append = (...) ->
    for arg in *{...}
      table.insert command, arg

  if opts.bwrap
    append "/usr/bin/bwrap",
      "--unshare-all", "--die-with-parent", "--new-session", "--clearenv"

    -- the loader and system libraries, wherever the distro keeps them
    for dir in *{"/usr/lib", "/usr/lib64", "/lib", "/lib64"}
      append "--ro-bind-try", dir, dir

    append "--ro-bind", luajit, "/luajit", "/luajit"
  else
    append luajit

  append "-e", source
  command

-- Runs the command inside nginx with ngx.pipe, which yields instead of
-- blocking the worker
run_pipe = (command, input, timeout) ->
  ngx_pipe = require "ngx.pipe"
  proc, err = ngx_pipe.spawn command
  return nil, "spawn failed: #{err}" unless proc

  ngx.update_time!
  deadline = ngx.now! + timeout

  -- ngx.pipe timeouts are per operation, so each one gets what's left of the
  -- deadline
  set_remaining = ->
    ms = math.floor (deadline - ngx.now!) * 1000
    return false if ms < 1
    proc\set_timeouts ms, ms, ms, ms
    true

  -- the child may exit before reading everything, so write errors are
  -- ignored and the result comes from what it printed
  set_remaining!
  proc\write input
  proc\shutdown "stdin"

  chunks = {}
  size = 0
  local failed
  while true
    unless set_remaining!
      failed = "timeout"
      break
    chunk, err = proc\stdout_read_any 64 * 1024
    unless chunk
      failed = err unless err == "closed"
      break
    size += #chunk
    if size > MAX_OUTPUT
      failed = "too much output"
      break
    table.insert chunks, chunk

  local stderr
  if failed or not set_remaining!
    failed or= "timeout"
    proc\kill 9
    proc\set_timeouts 1000, 1000, 1000, 1000
  else
    stderr = proc\stderr_read_any 4096

  ok, reason, status = proc\wait!
  unless ok or reason == "exit" or reason == "signal"
    proc\kill 9

  unless ok
    failed or= "child #{reason} #{status}"
    if stderr and stderr != ""
      failed ..= ": #{stderr}"

  table.concat(chunks), failed

-- Runs the command with io.popen, for scripts and tests outside of nginx.
-- The child's stderr goes to the caller's stderr
run_popen = (command, input, timeout) ->
  tmp = os.tmpname!
  f, err = io.open tmp, "wb"
  unless f
    os.remove tmp
    return nil, "failed to write input: #{err}"

  f\write input
  f\close!

  parts = { "timeout", "-s", "KILL", tostring(timeout) }
  for arg in *command
    table.insert parts, "'#{shell_escape arg}'"

  proc, err = io.popen "#{table.concat parts, " "} < '#{shell_escape tmp}'", "r"
  unless proc
    os.remove tmp
    return nil, "popen failed: #{err}"

  out = proc\read(MAX_OUTPUT + 1) or ""
  proc\close!
  os.remove tmp

  if #out > MAX_OUTPUT
    return out, "too much output"

  out

can_use_pipe = ->
  return false unless ngx and ngx.get_phase
  switch ngx.get_phase!
    when "rewrite", "access", "content", "timer"
      (pcall require, "ngx.pipe")
    else
      false

-- Returns the child's stdout, or nil if it couldn't be spawned. When the
-- child didn't exit cleanly the second value says why, and the output may be
-- partial
run_sandboxed = (source, input, opts=config.rockspec_sandbox) ->
  command = sandbox_command opts, source
  timeout = opts.timeout or 3

  if can_use_pipe!
    run_pipe command, input, timeout
  else
    run_popen command, input, timeout

-- Rebuilds data from the child's tagged JSON (tables are arrays of [key,
-- value] pairs). The child is untrusted, so anything unexpected fails
from_tagged = (v) ->
  switch type v
    when "string", "boolean"
      v
    when "number"
      v if is_finite v
    when "table"
      out = {}
      for pair in *v
        return nil unless type(pair) == "table" and #pair == 2
        k = pair[1]
        return nil unless type(k) == "string" or type(k) == "number" and is_finite k
        item = from_tagged pair[2]
        return nil if item == nil
        out[k] = item
      out

known_errors = {msg, true for _, msg in pairs ERRORS}

decode_result = (out) ->
  ok, res = pcall cjson.decode, out
  return nil, ERRORS.eval unless ok and type(res) == "table"

  if res.error != nil
    return nil, known_errors[res.error] and res.error or ERRORS.eval

  return nil, ERRORS.eval unless type(res.ok) == "table"
  spec = from_tagged res.ok
  return nil, ERRORS.eval unless spec
  spec

log_error = (msg) ->
  if ngx and ngx.log
    ngx.log ngx.ERR, msg
  else
    io.stderr\write msg, "\n"

eval_rockspec = (text) ->
  opts = config.rockspec_sandbox
  unless opts
    spec, err = sandbox.eval_rockspec text
    return nil, err unless spec
    return sandbox.to_data spec

  return nil, ERRORS.parse unless type(text) == "string"

  out, err = run_sandboxed get_sandbox_source!, text, opts

  -- the sandbox prints a newline when it starts, without it the rockspec
  -- was never evaluated
  unless out and out\sub(1, 1) == "\n"
    log_error "rockspec sandbox failed to start: #{err or "no output"}"
    return nil, ERRORS.sandbox

  if err
    log_error "rockspec sandbox failed: #{err}"

  decode_result out

{
  :eval_rockspec, :run_sandboxed, :sandbox_command, :get_sandbox_source,
  :decode_result
}
