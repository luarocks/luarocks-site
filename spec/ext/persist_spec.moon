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
   ['key\'quote'] = "value"
}
]], result

    it "quotes keys that are lua keywords", ->
      result = persist.save_from_table_to_string {
        settings: {["end"]: "finish", ["return"]: "back"}
      }
      assert.same [[settings = {
   ['end'] = "finish",
   ['return'] = "back"
}
]], result

    it "quotes keys with special characters", ->
      result = persist.save_from_table_to_string {
        mapping: {["my-key"]: "value", ["other.key"]: "data"}
      }
      assert.same [[mapping = {
   ['my-key'] = "value",
   ['other.key'] = "data"
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
   ['123'] = "numeric string key"
}
]], result
