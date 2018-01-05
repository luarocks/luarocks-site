
--- Dependency handling functions.
-- Dependencies are represented in LuaRocks through strings with
-- a package name followed by a comma-separated list of constraints.
-- Each constraint consists of an operator and a version number.
-- In this string format, version numbers are represented as
-- naturally as possible, like they are used by upstream projects
-- (e.g. "2.0beta3"). Internally, LuaRocks converts them to a purely
-- numeric representation, allowing comparison following some
-- "common sense" heuristics. The precise specification of the
-- comparison criteria is the source code of this module, but the
-- test/test_deps.lua file included with LuaRocks provides some
-- insights on what these criteria are.
module("ext.luarocks.deps", package.seeall)

local util = require("ext.luarocks.util")

local operators = {
   ["=="] = "==",
   ["~="] = "~=",
   [">"] = ">",
   ["<"] = "<",
   [">="] = ">=",
   ["<="] = "<=",
   ["~>"] = "~>",
   -- plus some convenience translations
   [""] = "==",
   ["="] = "==",
   ["!="] = "~="
}

local deltas = {
   scm =    1100,
   cvs =    1000,
   rc =    -1000,
   pre =   -10000,
   beta =  -100000,
   alpha = -1000000
}

local version_mt = {
   --- Equality comparison for versions.
   -- All version numbers must be equal.
   -- If both versions have revision numbers, they must be equal;
   -- otherwise the revision number is ignored.
   -- @param v1 table: version table to compare.
   -- @param v2 table: version table to compare.
   -- @return boolean: true if they are considered equivalent.
   __eq = function(v1, v2)
      if #v1 ~= #v2 then
         return false
      end
      for i = 1, #v1 do
         if v1[i] ~= v2[i] then
            return false
         end
      end
      if v1.revision and v2.revision then
         return (v1.revision == v2.revision)
      end
      return true
   end,
   --- Size comparison for versions.
   -- All version numbers are compared.
   -- If both versions have revision numbers, they are compared;
   -- otherwise the revision number is ignored.
   -- @param v1 table: version table to compare.
   -- @param v2 table: version table to compare.
   -- @return boolean: true if v1 is considered lower than v2.
   __lt = function(v1, v2)
      for i = 1, math.max(#v1, #v2) do
         local v1i, v2i = v1[i] or 0, v2[i] or 0
         if v1i ~= v2i then
            return (v1i < v2i)
         end
      end
      if v1.revision and v2.revision then
         return (v1.revision < v2.revision)
      end
      return false
   end
}

local version_cache = {}
setmetatable(version_cache, {
   __mode = "kv"
})

--- Parse a version string, converting to table format.
-- A version table contains all components of the version string
-- converted to numeric format, stored in the array part of the table.
-- If the version contains a revision, it is stored numerically
-- in the 'revision' field. The original string representation of
-- the string is preserved in the 'string' field.
-- Returned version tables use a metatable
-- allowing later comparison through relational operators.
-- @param vstring string: A version number in string format.
-- @return table or nil: A version table or nil
-- if the input string contains invalid characters.
function parse_version(vstring)
   if not vstring then return nil end
   assert(type(vstring) == "string")

   local cached = version_cache[vstring]
   if cached then
      return cached
   end

   local version = {}
   local i = 1

   local function add_token(number)
      version[i] = version[i] and version[i] + number/100000 or number
      i = i + 1
   end
   
   -- trim leading and trailing spaces
   vstring = vstring:match("^%s*(.*)%s*$")
   version.string = vstring
   -- store revision separately if any
   local main, revision = vstring:match("(.*)%-(%d+)$")
   if revision then
      vstring = main
      version.revision = tonumber(revision)
   end
   while #vstring > 0 do
      -- extract a number
      local token, rest = vstring:match("^(%d+)[%.%-%_]*(.*)")
      if token then
         add_token(tonumber(token))
      else
         -- extract a word
         token, rest = vstring:match("^(%a+)[%.%-%_]*(.*)")
         if not token then
            -- util.printerr("Warning: version number '"..vstring.."' could not be parsed.")
            version[i] = 0
            break
         end
         local last = #version
         version[i] = deltas[token] or (token:byte() / 1000)
      end
      vstring = rest
   end
   setmetatable(version, version_mt)
   version_cache[vstring] = version
   return version
end

--- Utility function to compare version numbers given as strings.
-- @param a string: one version.
-- @param b string: another version.
-- @return boolean: True if a > b.
function compare_versions(a, b)
   return parse_version(a) > parse_version(b)
end

--- Consumes a constraint from a string, converting it to table format.
-- For example, a string ">= 1.0, > 2.0" is converted to a table in the
-- format {op = ">=", version={1,0}} and the rest, "> 2.0", is returned
-- back to the caller.
-- @param input string: A list of constraints in string format.
-- @return (table, string) or nil: A table representing the same
-- constraints and the string with the unused input, or nil if the
-- input string is invalid.
local function parse_constraint(input)
   assert(type(input) == "string")

   local no_upgrade, op, version, rest = input:match("^(@?)([<>=~!]*)%s*([%w%.%_%-]+)[%s,]*(.*)")
   local _op = operators[op]
   version = parse_version(version)
   if not _op then
      return nil, "Encountered bad constraint operator: '"..tostring(op).."' in '"..input.."'"
   end
   if not version then 
      return nil, "Could not parse version from constraint: '"..input.."'"
   end
   return { op = _op, version = version, no_upgrade = no_upgrade=="@" and true or nil }, rest
end

--- Convert a list of constraints from string to table format.
-- For example, a string ">= 1.0, < 2.0" is converted to a table in the format
-- {{op = ">=", version={1,0}}, {op = "<", version={2,0}}}.
-- Version tables use a metatable allowing later comparison through
-- relational operators.
-- @param input string: A list of constraints in string format.
-- @return table or nil: A table representing the same constraints,
-- or nil if the input string is invalid.
function parse_constraints(input)
   assert(type(input) == "string")

   local constraints, constraint, oinput = {}, nil, input
   while #input > 0 do
      constraint, input = parse_constraint(input)
      if constraint then
         table.insert(constraints, constraint)
      else
         return nil, "Failed to parse constraint '"..tostring(oinput).."' with error: ".. input
      end
   end
   return constraints
end

--- Convert a dependency from string to table format.
-- For example, a string "foo >= 1.0, < 2.0"
-- is converted to a table in the format
-- {name = "foo", constraints = {{op = ">=", version={1,0}},
-- {op = "<", version={2,0}}}}. Version tables use a metatable
-- allowing later comparison through relational operators.
-- @param dep string: A dependency in string format
-- as entered in rockspec files.
-- @return table or nil: A table representing the same dependency relation,
-- or nil if the input string is invalid.
function parse_dep(dep)
   assert(type(dep) == "string")

   local name, rest = dep:match("^%s*([a-zA-Z0-9][a-zA-Z0-9%.%-%_]*)%s*(.*)")
   if not name then return nil, "failed to extract dependency name from '"..tostring(dep).."'" end
   local constraints, err = parse_constraints(rest)
   if not constraints then return nil, err end
   return { name = name, constraints = constraints }
end

--- A more lenient check for equivalence between versions.
-- This returns true if the requested components of a version
-- match and ignore the ones that were not given. For example,
-- when requesting "2", then "2", "2.1", "2.3.5-9"... all match.
-- When requesting "2.1", then "2.1", "2.1.3" match, but "2.2"
-- doesn't.
-- @param version string or table: Version to be tested; may be
-- in string format or already parsed into a table.
-- @param requested string or table: Version requested; may be
-- in string format or already parsed into a table.
-- @return boolean: True if the tested version matches the requested
-- version, false otherwise.
local function partial_match(version, requested)
   assert(type(version) == "string" or type(version) == "table")
   assert(type(requested) == "string" or type(version) == "table")

   if type(version) ~= "table" then version = parse_version(version) end
   if type(requested) ~= "table" then requested = parse_version(requested) end
   if not version or not requested then return false end
   
   for i, ri in ipairs(requested) do
      local vi = version[i] or 0
      if ri ~= vi then return false end
   end
   if requested.revision then
      return requested.revision == version.revision
   end
   return true
end

--- Check if a version satisfies a set of constraints.
-- @param version table: A version in table format
-- @param constraints table: An array of constraints in table format.
-- @return boolean: True if version satisfies all constraints,
-- false otherwise.
function match_constraints(version, constraints)
   assert(type(version) == "table")
   assert(type(constraints) == "table")
   local ok = true
   setmetatable(version, version_mt)
   for _, constr in pairs(constraints) do
      if type(constr.version) == "string" then
         constr.version = parse_version(constr.version)
      end
      local constr_version, constr_op = constr.version, constr.op
      setmetatable(constr_version, version_mt)
      if     constr_op == "==" then ok = version == constr_version
      elseif constr_op == "~=" then ok = version ~= constr_version
      elseif constr_op == ">"  then ok = version >  constr_version
      elseif constr_op == "<"  then ok = version <  constr_version
      elseif constr_op == ">=" then ok = version >= constr_version
      elseif constr_op == "<=" then ok = version <= constr_version
      elseif constr_op == "~>" then ok = partial_match(version, constr_version)
      end
      if not ok then break end
   end
   return ok
end

