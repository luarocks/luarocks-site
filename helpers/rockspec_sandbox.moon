-- Evaluates an untrusted rockspec and copies the result into plain data.
--
-- This file must stay self-contained (no requires): helpers/rockspec_eval.moon
-- also runs it on its own as the program of a child process, where it reads
-- the rockspec on stdin and writes the result to stdout as JSON.

MAX_DEPTH = 32
MAX_NODES = 100000
MAX_BYTES = 1024 * 1024

-- Error messages for a rockspec that can't be evaluated. The child reports
-- these to the parent, besides sandbox which is for a child that didn't run
ERRORS = {
  parse: "Failed to parse rockspec"
  eval: "Failed to eval rockspec"
  complex: "Invalid rockspec (too complex)"
  sandbox: "Failed to run rockspec sandbox"
}

-- NOTE: this takes untrusted input, so be very strict about parsing
-- prefer failing instead of fixing inputs
eval_rockspec = (text) ->
  return nil, ERRORS.parse unless type(text) == "string"

  -- remove #! if it's there
  text = text\gsub "^%#[^\n]*", ""

  -- only allow text chunks, precompiled bytecode is unchecked by luajit and
  -- can be used to escape the sandbox. The explicit check is for interpreters
  -- that ignore the mode argument (eg. PUC Lua 5.1)
  return nil, ERRORS.parse if text\find "^%s*\27"
  fn = loadstring text, "rockspec", "t"
  return nil, ERRORS.parse unless fn
  spec = {}
  setfenv fn, spec

  -- disable jit otherwise the offending code might be compiled and stop
  -- sending debug events
  jit and jit.off fn

  co = coroutine.create fn
  lines = 0

  check = ->
    lines += 1
    if lines > 2000
      debug.sethook! if jit -- remove the global hook set by luajit
      error "too many lines evaluated"

  -- luajit does not appear to let you set debug hook on coroutine, it just
  -- applies globally. We do it anyway incase this is ever fixed. Additionally
  -- it's impossible to capture the error raised in a hook, so it just forces
  -- 500 from openresty
  debug.sethook co, check, "l"
  status = pcall -> assert coroutine.resume co
  debug.sethook co

  unless status
    return nil, ERRORS.eval

  spec

is_finite = (n) -> n == n and n != 1/0 and n != -1/0

-- Copies the evaluated spec into a tree of strings, finite numbers, booleans,
-- and tables with string or number keys. Anything else (functions, other key
-- types) is dropped. Cycles and oversized trees (by depth, node count, or
-- total string bytes) are rejected.
to_data = (value) ->
  nodes = 0
  bytes = 0
  path = {}

  count_bytes = (str) ->
    bytes += #str
    error ERRORS.complex if bytes > MAX_BYTES

  local copy
  copy = (v, depth) ->
    switch type v
      when "string"
        count_bytes v
        v
      when "boolean"
        v
      when "number"
        v if is_finite v
      when "table"
        error ERRORS.complex if depth > MAX_DEPTH or path[v]
        path[v] = true
        out = {}
        k, item = next v
        while k != nil
          nodes += 1
          error ERRORS.complex if nodes > MAX_NODES

          key_ok = switch type k
            when "string"
              count_bytes k
              true
            when "number"
              is_finite k

          if key_ok
            out[k] = copy item, depth + 1

          k, item = next v, k

        path[v] = nil
        out

  ok, res = pcall copy, value, 1
  unless ok
    return nil, ERRORS.complex

  res

-- JSON encoding of plain data in a form that keeps key types: every table is
-- an array of [key, value] pairs. Bytes >= 0x80 are written as is, so strings
-- round trip exactly.
escape_char = (c) -> string.format "\\u%04x", c\byte!

encode_string = (s) ->
  '"' .. s\gsub('[%c"\\]', escape_char) .. '"'

local encode_value
encode_value = (v, buffer) ->
  switch type v
    when "string"
      table.insert buffer, encode_string v
    when "number"
      table.insert buffer, string.format "%.17g", v
    when "boolean"
      table.insert buffer, tostring v
    when "table"
      table.insert buffer, "["
      first = true
      for k, item in pairs v
        table.insert buffer, "," unless first
        first = false
        table.insert buffer, "["
        encode_value k, buffer
        table.insert buffer, ","
        encode_value item, buffer
        table.insert buffer, "]"
      table.insert buffer, "]"
    else
      error "can't encode #{type v}"

encode_result = (data, err) ->
  if data == nil
    return '{"error":' .. encode_string(err) .. '}'

  buffer = {'{"ok":'}
  encode_value data, buffer
  table.insert buffer, "}"
  table.concat buffer

-- The child inherits any descriptor the parent opened without close-on-exec,
-- and an escape from the sandbox should find nothing open besides stdin,
-- stdout, and stderr
close_inherited_fds = ->
  ok, ffi = pcall require, "ffi"
  return unless ok
  pcall ffi.cdef, [[
    int close(int fd);
    int close_range(unsigned int first, unsigned int last, int flags);
  ]]

  -- close_range is missing from older libcs (pcall fails) and fails on older
  -- kernels (returns -1)
  ok, res = pcall -> ffi.C.close_range 3, 0xffffffff, 0
  unless ok and res == 0
    for fd = 3, 4095
      ffi.C.close fd

run_child = ->
  close_inherited_fds!
  jit.off! if jit

  -- tells the parent that the sandbox started, so it can tell a rockspec
  -- that killed the child apart from a child that never ran
  io.write "\n"
  io.stdout\flush!

  text = io.read "*a"
  spec, err = eval_rockspec text
  data = if spec
    to_data spec

  err = ERRORS.complex if spec and not data
  io.write encode_result data, err

-- Run as a program when loaded without a module name
if select("#", ...) == 0
  return run_child!

{
  :eval_rockspec, :to_data, :encode_result, :close_inherited_fds, :is_finite,
  :ERRORS
}
