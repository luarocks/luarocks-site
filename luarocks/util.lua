module("luarocks.util", package.seeall)

--- Return an array of keys of a table.
-- @param tbl table: The input table.
-- @return table: The array of keys.
function keys(tbl)
   local ks = {}
   for k,_ in pairs(tbl) do
      table.insert(ks, k)
   end
   return ks
end

local function default_sort(a, b)
   local ta = type(a)
   local tb = type(b)
   if ta == "number" and tb == "number" then
      return a < b
   elseif ta == "number" then
      return true
   elseif tb == "number" then
      return false
   else
      return tostring(a) < tostring(b)
   end
end

-- The iterator function used internally by util.sortedpairs.
-- @param tbl table: The table to be iterated.
-- @param sort_function function or nil: An optional comparison function
-- to be used by table.sort when sorting keys.
-- @see sortedpairs
local function sortedpairs_iterator(tbl, sort_function)
   local ks = keys(tbl)
   if not sort_function or type(sort_function) == "function" then
      table.sort(ks, sort_function or default_sort)
      for _, k in ipairs(ks) do
         coroutine.yield(k, tbl[k])
      end
   else
      local order = sort_function
      local done = {}
      for _, k in ipairs(order) do
         local sub_order
         if type(k) == "table" then
            sub_order = k[2]
            k = k[1]
         end
         if tbl[k] then
            done[k] = true
            coroutine.yield(k, tbl[k], sub_order)
         end
      end
      table.sort(ks, default_sort)
      for _, k in ipairs(ks) do
         if not done[k] then
            coroutine.yield(k, tbl[k])
         end
      end
   end
end

--- A table iterator generator that returns elements sorted by key,
-- to be used in "for" loops.
-- @param tbl table: The table to be iterated.
-- @param sort_function function or table or nil: An optional comparison function
-- to be used by table.sort when sorting keys, or an array listing an explicit order
-- for keys. If a value itself is an array, it is taken so that the first element
-- is a string representing the field name, and the second element is a priority table
-- for that key.
-- @return function: the iterator function.
function sortedpairs(tbl, sort_function)
   return coroutine.wrap(function() sortedpairs_iterator(tbl, sort_function) end)
end
