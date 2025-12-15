persist = require "ext.luarocks.persist"

describe "ext.luarocks.persist", ->
  describe "save_from_table_to_string", ->
    it "serializes simple string value", ->
      result = persist.save_from_table_to_string {
        name: "hello"
      }
      assert.same 'name = "hello"\n', result

    it "serializes simple number value", ->
      result = persist.save_from_table_to_string {
        count: 42
      }
      assert.same 'count = 42\n', result

    it "serializes boolean values", ->
      result = persist.save_from_table_to_string {
        enabled: true
      }
      assert.same 'enabled = true\n', result

      result = persist.save_from_table_to_string {
        disabled: false
      }
      assert.same 'disabled = false\n', result

    it "serializes multiple fields in sorted order", ->
      result = persist.save_from_table_to_string {
        zebra: "last"
        apple: "first"
        mango: "middle"
      }
      assert.same [[apple = "first"
mango = "middle"
zebra = "last"
]], result

    it "serializes nested table", ->
      result = persist.save_from_table_to_string {
        config: {
          host: "localhost"
          port: 8080
        }
      }
      assert.same [[config = {
   host = "localhost",
   port = 8080
}
]], result

    it "serializes array values", ->
      result = persist.save_from_table_to_string {
        items: {"one", "two", "three"}
      }
      assert.same [[items = {
   "one", "two", "three"
}
]], result

    it "serializes mixed array and hash table", ->
      result = persist.save_from_table_to_string {
        data: {"first", "second", name: "test"}
      }
      assert.same [[data = {
   "first", "second", name = "test"
}
]], result

    it "serializes non-sequential numeric keys", ->
      result = persist.save_from_table_to_string {
        sparse: {[1]: "a", [5]: "b", [10]: "c"}
      }
      assert.same [[sparse = {
   "a", [5]="b", [10]="c"
}
]], result

    it "escapes quotes in strings", ->
      result = persist.save_from_table_to_string {
        message: 'say "hello"'
      }
      assert.same [[message = "say \"hello\""
]], result

    it "uses long brackets for multiline strings", ->
      result = persist.save_from_table_to_string {
        text: "line1\nline2\nline3"
      }
      assert.same [==[text = [[
line1
line2
line3]]
]==], result

    it "handles multiline strings containing brackets", ->
      result = persist.save_from_table_to_string {
        code: "data = [[inner]]\nmore"
      }
      assert.same [====[code = [=[
data = [[inner]]
more]=]
]====], result

    it "escapes single quotes in bracket-style keys", ->
      result = persist.save_from_table_to_string {
        data: {["key'quote"]: "value"}
      }
      assert.same [[data = {
   ["key'quote"] = "value"
}
]], result

    it "quotes keys that are lua keywords", ->
      result = persist.save_from_table_to_string {
        settings: {["end"]: "finish", ["return"]: "back"}
      }
      assert.same [[settings = {
   ["end"] = "finish",
   ["return"] = "back"
}
]], result

    it "quotes keys with special characters", ->
      result = persist.save_from_table_to_string {
        mapping: {["my-key"]: "value", ["other.key"]: "data"}
      }
      assert.same [[mapping = {
   ["my-key"] = "value",
   ["other.key"] = "data"
}
]], result

    it "serializes deeply nested tables", ->
      result = persist.save_from_table_to_string {
        level1: {
          level2: {
            level3: {
              value: "deep"
            }
          }
        }
      }
      assert.same [[level1 = {
   level2 = {
      level3 = {
         value = "deep"
      }
   }
}
]], result

    it "respects field_order parameter", ->
      result = persist.save_from_table_to_string {
        zebra: "last"
        apple: "first"
        mango: "middle"
      }, {"mango", "apple", "zebra"}
      assert.same [[mango = "middle"
apple = "first"
zebra = "last"
]], result

    it "serializes empty table", ->
      result = persist.save_from_table_to_string {
        empty: {}
      }
      assert.same "empty = {}\n", result

    it "handles numeric string keys", ->
      result = persist.save_from_table_to_string {
        data: {["123"]: "numeric string key"}
      }
      assert.same [[data = {
   ["123"] = "numeric string key"
}
]], result

  describe "security edge cases", ->
    -- Helper to verify roundtrip: serialize then load should return original value
    roundtrip = (tbl) ->
      result = persist.save_from_table_to_string tbl
      -- Load the result as Lua code
      env = {}
      fn, err = if setfenv
        -- Lua 5.1
        chunk, load_err = loadstring result
        if chunk
          setfenv chunk, env
        chunk, load_err
      else
        -- Lua 5.2+
        load result, "persist_output", "t", env

      assert fn, "Failed to parse output as Lua: #{err}\nOutput was:\n#{result}"
      fn!
      env, result

    it "escapes backslashes in strings", ->
      result = persist.save_from_table_to_string {
        path: "C:\\Users\\test"
      }
      -- Backslashes should be escaped so the output is valid Lua
      assert.same [[path = "C:\\Users\\test"
]], result

    it "prevents quote escape injection (backslash before quote)", ->
      -- This is the classic injection: \" in input becomes \\" in naive escaping
      -- which means escaped-backslash + unescaped-quote = string termination
      result = persist.save_from_table_to_string {
        payload: '\\"'
      }
      -- Should properly escape both backslash and quote
      assert.same [[payload = "\\\""
]], result

    it "prevents code injection via backslash-quote sequence", ->
      -- Attempt to inject code: the payload tries to close the string and add code
      malicious = '\\", evil = true, x = "'
      -- Verify it roundtrips correctly (original value is preserved, no injection)
      loaded = roundtrip { data: malicious }
      assert.same malicious, loaded.data

    it "handles multiple backslashes before quote", ->
      loaded = roundtrip { test: '\\\\"' }
      assert.same '\\\\"', loaded.test

    it "escapes backslashes in keys", ->
      loaded = roundtrip { data: {["key\\'inject"]: "value"} }
      assert.same "value", loaded.data["key\\'inject"]

    it "handles null bytes in strings", ->
      loaded = roundtrip { binary: "before\0after" }
      assert.same "before\0after", loaded.binary

    it "handles carriage return characters", ->
      loaded, code = roundtrip { text: "line1\r\nline2" }
      assert.same "text = [[
line1\r\nline2]]
", code

      -- NOTE: \r is stripped when loaded back in a [[ ]] string
      assert.same "line1\nline2", loaded.text

    it "handles tab characters", ->
      loaded = roundtrip { text: "col1\tcol2" }
      assert.same "col1\tcol2", loaded.text

    it "handles all escape sequences together", ->
      complex = 'a"b\'c\\d\ne\rf\tg\0h'
      loaded, code  = roundtrip { complex: complex }
-- The exact output changes based on the lua version, so commented out for now
--       assert.same [[
-- complex = "a\"b'c\\d\
-- e\rf	g\000h"
-- ]], code

      assert.same complex, loaded.complex

    it "prevents injection in nested table values", ->
      malicious = '\\", injected = true, ignore = "'
      loaded = roundtrip { outer: { inner: malicious } }
      assert.same malicious, loaded.outer.inner
      assert.is_nil loaded.outer.injected

    it "prevents injection in array values", ->
      malicious = '\\", print("pwned"), "'
      loaded = roundtrip { items: {"safe", malicious, "also safe"} }
      assert.same malicious, loaded.items[2]

    it "handles long bracket edge case with equals signs", ->
      -- String that contains ]=] should use higher bracket level
      tricky = "end]=]more"
      loaded = roundtrip { text: "line1\n#{tricky}" }
      assert.same "line1\n#{tricky}", loaded.text

    it "handles string that looks like long bracket close at all levels", ->
      -- Try to break out of any bracket level
      tricky = "]]\n]=]\n]==]\n]===]"
      loaded = roundtrip { text: "start\n#{tricky}\nend" }
      assert.same "start\n#{tricky}\nend", loaded.text
